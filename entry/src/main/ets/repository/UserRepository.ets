import { User } from '../model/User';
import { ApiClient } from '../service/ApiClient';
import { Result } from '../utils/Result';

/** 云端 user_info 的 JSON 形状。 */
interface UserDto {
  openid: string;
  nickname?: string;
  avatarUrl?: string;
  phone?: string;
  createdAt?: string;
  updatedAt?: string;
}

/** 提交给后端的用户可写字段。 */
interface UserReq {
  nickname: string;
  avatarUrl: string;
}

/**
 * 用户仓储（在线优先）：对接云端 /user。
 * 注册/登录由 AuthService 直连 /auth/*；此处只负责读取与更新当前用户资料。
 */
export class UserRepository {
  private static toUser(d: UserDto): User {
    return new User(d.openid, '', '', '', d.nickname ?? '', d.avatarUrl ?? '', d.createdAt ?? '');
  }

  /** 读取当前登录用户（由 token 决定）。 */
  static async getCurrent(): Promise<User | null> {
    const r: Result<UserDto> = await ApiClient.get<UserDto>('/user');
    if (!r.success || r.data === null) {
      return null;
    }
    return UserRepository.toUser(r.data);
  }

  /** 更新当前用户昵称/头像。 */
  static async saveProfile(nickname: string, avatar: string): Promise<void> {
    const req: UserReq = { nickname: nickname, avatarUrl: avatar };
    ApiClient.unwrap(await ApiClient.post<UserDto>('/user', req));
  }
}
