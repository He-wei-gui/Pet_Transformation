/**
 * 云端后端（server/）接口配置。
 * 后端部署在阿里云，所有接口前缀 /api，详见 server/DEPLOY.md。
 */
export class ApiConfig {
  /** 接口根地址（含 /api 前缀），结尾不带斜杠。 */
  static readonly BASE_URL: string = 'https://api.lysyminger.online/api';

  /** 单次请求超时（毫秒）。 */
  static readonly CONNECT_TIMEOUT: number = 10000;
  static readonly READ_TIMEOUT: number = 15000;
}
