import { Result } from '../utils/Result';
import { ApiClient } from './ApiClient';
import { UserRepository } from '../repository/UserRepository';
import { User } from '../model/User';
import { SessionStore } from './SessionStore';
import { Logger } from '../utils/Logger';

/** /auth/register 与 /auth/login-app 的响应。 */
interface AuthResp {
  token: string;
  openid: string;
}

interface RegisterReq {
  username: string;
  password: string;
  nickname: string;
  email: string;
  code: string;
}

interface LoginReq {
  username: string;
  password: string;
}

interface SendCodeReq {
  email: string;
  purpose: string;
}

interface ResetPwdReq {
  username: string;
  email: string;
  code: string;
  password: string;
}

interface OkResp {
  sent?: boolean;
  reset?: boolean;
}

/**
 * 鉴权服务（在线优先）：注册 / 登录 / 退出直连云端 /auth/*，
 * 成功后持久化 openid + token。资料更新走 /user。
 */
export class AuthService {
  /** 发送邮箱验证码。purpose: 'register' | 'reset'。 */
  static async sendCode(email: string, purpose: string): Promise<Result<string>> {
    const req: SendCodeReq = { email: email.trim().toLowerCase(), purpose: purpose };
    const r: Result<OkResp> = await ApiClient.postPublic<OkResp>('/auth/send-code', req);
    if (!r.success) {
      return Result.fail(r.error.length > 0 ? r.error : 'err_server');
    }
    return Result.ok('');
  }

  /** 注册（含邮箱验证码）：成功后保存会话，返回 openid。 */
  static async register(username: string, password: string, nickname: string,
    email: string, code: string): Promise<Result<string>> {
    const name: string = username.trim();
    const nick: string = nickname.trim().length > 0 ? nickname.trim() : name;
    const req: RegisterReq = {
      username: name, password: password, nickname: nick,
      email: email.trim().toLowerCase(), code: code.trim()
    };
    const r: Result<AuthResp> = await ApiClient.postPublic<AuthResp>('/auth/register', req);
    if (!r.success || r.data === null) {
      return Result.fail(r.error.length > 0 ? r.error : 'err_register_failed');
    }
    await SessionStore.save(r.data.openid, nick, r.data.token);
    return Result.ok(r.data.openid);
  }

  /** 找回密码：用户名 + 邮箱 + 验证码 + 新密码。 */
  static async resetPassword(username: string, email: string, code: string,
    password: string): Promise<Result<string>> {
    const req: ResetPwdReq = {
      username: username.trim(), email: email.trim().toLowerCase(),
      code: code.trim(), password: password
    };
    const r: Result<OkResp> = await ApiClient.postPublic<OkResp>('/auth/reset-password', req);
    if (!r.success) {
      return Result.fail(r.error.length > 0 ? r.error : 'err_server');
    }
    return Result.ok('');
  }

  /** 登录：成功后保存会话，并拉取云端资料刷新昵称。返回 openid。 */
  static async login(username: string, password: string): Promise<Result<string>> {
    const name: string = username.trim();
    const req: LoginReq = { username: name, password: password };
    const r: Result<AuthResp> = await ApiClient.postPublic<AuthResp>('/auth/login-app', req);
    if (!r.success || r.data === null) {
      return Result.fail(r.error.length > 0 ? r.error : 'err_login_invalid');
    }
    // 先用用户名占位保存（含 token），再拉取真实昵称
    await SessionStore.save(r.data.openid, name, r.data.token);
    try {
      const user: User | null = await UserRepository.getCurrent();
      if (user !== null && user.nickname.length > 0) {
        await SessionStore.save(r.data.openid, user.nickname, r.data.token);
      }
    } catch (err) {
      Logger.error(`fetch profile after login failed: ${JSON.stringify(err)}`);
    }
    return Result.ok(r.data.openid);
  }

  static async logout(): Promise<void> {
    await SessionStore.clear();
  }

  /** 更新昵称/头像/邮箱，同步刷新会话昵称。 */
  static async updateProfile(userId: string, nickname: string, avatar: string,
    email: string): Promise<Result<string>> {
    try {
      const nick: string = nickname.trim();
      await UserRepository.saveProfile(nick, avatar, email.trim().toLowerCase());
      await SessionStore.save(SessionStore.currentUserId(), nick, SessionStore.currentToken());
      return Result.ok(userId);
    } catch (err) {
      Logger.error(`updateProfile failed: ${JSON.stringify(err)}`);
      return Result.fail('err_server');
    }
  }

  /** 改密：后端暂未提供该接口。 */
  static async changePassword(userId: string, oldPwd: string, newPwd: string): Promise<Result<string>> {
    return Result.fail('当前版本暂不支持修改密码');
  }
}
