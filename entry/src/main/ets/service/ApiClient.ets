import { http } from '@kit.NetworkKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { ApiConfig } from '../constants/ApiConfig';
import { Result } from '../utils/Result';
import { SessionStore } from './SessionStore';
import { Logger } from '../utils/Logger';

/** 后端错误响应体形状：{ error: "..." } */
interface ErrorBody {
  error?: string;
}

/** /uploads 成功响应：原图地址 + 缩略图地址。 */
export interface UploadResult {
  url: string;
  thumb?: string;
}

/**
 * 云端后端统一 HTTP 客户端（在线优先架构的网络层）。
 * - 自动附带 Authorization: Bearer <token>
 * - 统一把响应规整为 Result<T>，错误转换为可被 I18n 解析的资源键或后端文案
 * - 普通接口遇 401 视为会话失效（清登录态）；登录/注册类接口用 *Public 方法，401 透传后端文案
 */
export class ApiClient {
  static get<T>(path: string): Promise<Result<T>> {
    return ApiClient.request<T>(http.RequestMethod.GET, path, undefined, true);
  }

  static post<T>(path: string, body: object): Promise<Result<T>> {
    return ApiClient.request<T>(http.RequestMethod.POST, path, body, true);
  }

  static put<T>(path: string, body: object): Promise<Result<T>> {
    return ApiClient.request<T>(http.RequestMethod.PUT, path, body, true);
  }

  static del<T>(path: string): Promise<Result<T>> {
    return ApiClient.request<T>(http.RequestMethod.DELETE, path, undefined, true);
  }

  /** 登录/注册类：不带会话失效跳转，4xx 透传后端中文文案。 */
  static postPublic<T>(path: string, body: object): Promise<Result<T>> {
    return ApiClient.request<T>(http.RequestMethod.POST, path, body, false);
  }

  /**
   * 上传图片到 /uploads（multipart/form-data，字段名 file）。
   * 手动拼装 multipart 包体走 http，以便直接拿到 JSON 响应 {url, thumb}。
   * @param uri 图库选中的图片 uri（可被 fileIo 只读打开）
   */
  static async uploadImage(uri: string): Promise<Result<UploadResult>> {
    const req: http.HttpRequest = http.createHttp();
    let srcFd: number = -1;
    try {
      const file: fs.File = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      srcFd = file.fd;
      const size: number = fs.statSync(file.fd).size;
      const fileBuf: ArrayBuffer = new ArrayBuffer(size);
      fs.readSync(file.fd, fileBuf);
      fs.closeSync(file);
      srcFd = -1;

      const boundary: string = `----HMBoundary${Date.now()}${Math.floor(Math.random() * 1000000)}`;
      const head: Uint8Array = ApiClient.asciiBytes(
        `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="photo.jpg"\r\n` +
        `Content-Type: image/jpeg\r\n\r\n`);
      const tail: Uint8Array = ApiClient.asciiBytes(`\r\n--${boundary}--\r\n`);
      const fileBytes: Uint8Array = new Uint8Array(fileBuf);
      const body: Uint8Array = new Uint8Array(head.length + fileBytes.length + tail.length);
      body.set(head, 0);
      body.set(fileBytes, head.length);
      body.set(tail, head.length + fileBytes.length);

      const header: Record<string, string> = { 'Content-Type': `multipart/form-data; boundary=${boundary}` };
      const token: string = SessionStore.currentToken();
      if (token.length > 0) {
        header['Authorization'] = `Bearer ${token}`;
      }
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: header,
        connectTimeout: ApiConfig.CONNECT_TIMEOUT,
        readTimeout: ApiConfig.UPLOAD_TIMEOUT,
        expectDataType: http.HttpDataType.STRING,
        extraData: body.buffer
      };

      const resp: http.HttpResponse = await req.request(ApiConfig.BASE_URL + '/uploads', options);
      const code: number = resp.responseCode;
      const text: string = typeof resp.result === 'string' ? resp.result : '';
      if (code >= 200 && code < 300) {
        return Result.ok(JSON.parse(text.length > 0 ? text : 'null') as UploadResult);
      }
      Logger.error(`api upload -> HTTP ${code}: ${text.substring(0, 300)}`);
      if (code === 401) {
        await SessionStore.clear();
        return Result.fail('err_unauthorized');
      }
      if (code >= 500) {
        return Result.fail('err_server');
      }
      return Result.fail(ApiClient.parseError(text));
    } catch (err) {
      if (srcFd >= 0) {
        try {
          fs.closeSync(srcFd);
        } catch (e) {
        }
      }
      Logger.error(`api upload failed: ${JSON.stringify(err)}`);
      return Result.fail('err_network');
    } finally {
      req.destroy();
    }
  }

  /** 把纯 ASCII 字符串转字节（multipart 头部/边界均为 ASCII，无需 TextEncoder）。 */
  private static asciiBytes(s: string): Uint8Array {
    const bytes: Uint8Array = new Uint8Array(s.length);
    for (let i: number = 0; i < s.length; i++) {
      bytes[i] = s.charCodeAt(i) & 0xff;
    }
    return bytes;
  }

  /** 解包 Result：成功返回数据，失败抛出携带 messageKey 的异常（供仓储层使用）。 */
  static unwrap<T>(r: Result<T>): T {
    if (!r.success) {
      throw new Error(r.error);
    }
    return r.data as T;
  }

  private static async request<T>(method: http.RequestMethod, path: string,
    body: object | undefined, sessionGuard: boolean): Promise<Result<T>> {
    const req: http.HttpRequest = http.createHttp();
    try {
      const header: Record<string, string> = { 'Content-Type': 'application/json' };
      const token: string = SessionStore.currentToken();
      if (token.length > 0) {
        header['Authorization'] = `Bearer ${token}`;
      }
      const options: http.HttpRequestOptions = {
        method: method,
        header: header,
        connectTimeout: ApiConfig.CONNECT_TIMEOUT,
        readTimeout: ApiConfig.READ_TIMEOUT,
        expectDataType: http.HttpDataType.STRING
      };
      if (body !== undefined) {
        options.extraData = JSON.stringify(body);
      }

      const resp: http.HttpResponse = await req.request(ApiConfig.BASE_URL + path, options);
      const code: number = resp.responseCode;
      const text: string = typeof resp.result === 'string' ? resp.result : '';

      if (code >= 200 && code < 300) {
        const data: T = JSON.parse(text.length > 0 ? text : 'null') as T;
        return Result.ok(data);
      }

      Logger.error(`api ${method} ${path} -> HTTP ${code}: ${text.substring(0, 300)}`);
      if (code === 401 && sessionGuard) {
        await SessionStore.clear();
        return Result.fail('err_unauthorized');
      }
      if (code >= 500) {
        return Result.fail('err_server');
      }
      // 4xx：优先透传后端文案（中文），否则兜底
      return Result.fail(ApiClient.parseError(text));
    } catch (err) {
      Logger.error(`api ${method} ${path} failed: ${JSON.stringify(err)}`);
      return Result.fail('err_network');
    } finally {
      req.destroy();
    }
  }

  private static parseError(text: string): string {
    if (text.length === 0) {
      return 'err_server';
    }
    try {
      const body: ErrorBody = JSON.parse(text) as ErrorBody;
      return body.error !== undefined && body.error.length > 0 ? body.error : 'err_server';
    } catch (e) {
      return 'err_server';
    }
  }
}
