import { User } from '../model/User';
import { UserRepository } from '../repository/UserRepository';
import { Hash } from '../utils/Hash';
import { Result } from '../utils/Result';
import { DateUtil } from '../utils/DateUtil';
import { SessionStore } from './SessionStore';
import { SeedService } from './SeedService';
import { Logger } from '../utils/Logger';

/**
 * 鉴权服务：注册 / 登录 / 退出。本地校验，密码加盐哈希存储。
 */
export class AuthService {
  /** 注册：用户名唯一，成功后写入演示数据并保存会话。返回新用户 id。 */
  static async register(username: string, password: string, nickname: string): Promise<Result<number>> {
    try {
      const trimmedName: string = username.trim();
      const existing: User | null = await UserRepository.findByUsername(trimmedName);
      if (existing !== null) {
        return Result.fail('用户名已被占用');
      }
      const salt: string = Hash.generateSalt();
      const hash: string = await Hash.sha256(salt, password);
      const finalNickname: string = nickname.trim().length > 0 ? nickname.trim() : trimmedName;
      const user: User = new User(0, trimmedName, hash, salt, finalNickname, '', DateUtil.today());
      const id: number = await UserRepository.create(user);
      await SeedService.seedIfEmpty(id);
      await SessionStore.save(id, finalNickname);
      return Result.ok(id);
    } catch (err) {
      Logger.error(`register failed: ${JSON.stringify(err)}`);
      return Result.fail('注册失败，请稍后重试');
    }
  }

  /** 登录：校验用户名与密码哈希，成功后保存会话。返回用户 id。 */
  static async login(username: string, password: string): Promise<Result<number>> {
    try {
      const user: User | null = await UserRepository.findByUsername(username.trim());
      if (user === null) {
        return Result.fail('用户名或密码错误');
      }
      const hash: string = await Hash.sha256(user.salt, password);
      if (hash !== user.passwordHash) {
        return Result.fail('用户名或密码错误');
      }
      await SessionStore.save(user.id, user.nickname);
      return Result.ok(user.id);
    } catch (err) {
      Logger.error(`login failed: ${JSON.stringify(err)}`);
      return Result.fail('登录失败，请稍后重试');
    }
  }

  static async logout(): Promise<void> {
    await SessionStore.clear();
  }
}
