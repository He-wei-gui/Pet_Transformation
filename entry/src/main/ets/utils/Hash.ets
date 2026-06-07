import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { Logger } from './Logger';

/**
 * 密码哈希工具。本地演示用：salt + 密码做 SHA256，永不明文落库。
 * 注意：仅用于课程演示，生产环境应使用 PBKDF2/scrypt 等慢哈希。
 */
export class Hash {
  private static bytesToHex(bytes: Uint8Array): string {
    let hex: string = '';
    for (let i: number = 0; i < bytes.length; i++) {
      const b: number = bytes[i];
      hex += (b < 16 ? '0' : '') + b.toString(16);
    }
    return hex;
  }

  /** 生成随机盐（十六进制字符串）。 */
  static generateSalt(): string {
    try {
      const rand: cryptoFramework.Random = cryptoFramework.createRandom();
      const blob: cryptoFramework.DataBlob = rand.generateRandomSync(16);
      return Hash.bytesToHex(blob.data);
    } catch (err) {
      Logger.error(`generateSalt failed: ${JSON.stringify(err)}`);
      return `${Date.now()}`;
    }
  }

  /** 计算 SHA256(salt + password) 的十六进制摘要。 */
  static async sha256(salt: string, password: string): Promise<string> {
    const md: cryptoFramework.Md = cryptoFramework.createMd('SHA256');
    const encoder: util.TextEncoder = new util.TextEncoder();
    const input: cryptoFramework.DataBlob = { data: encoder.encodeInto(salt + password) };
    await md.update(input);
    const digest: cryptoFramework.DataBlob = await md.digest();
    return Hash.bytesToHex(digest.data);
  }
}
