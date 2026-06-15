/**
 * 用户实体。接入云端后 id 为 openid（字符串）。
 * 密码改由云端用 password_hash 存储，端上不再保存 passwordHash/salt（保留字段仅为兼容，通常为空）。
 */
export class User {
  id: string;
  username: string;
  passwordHash: string;
  salt: string;
  nickname: string;
  avatar: string;
  createdAt: string;

  constructor(id: string, username: string, passwordHash: string, salt: string,
    nickname: string, avatar: string, createdAt: string) {
    this.id = id;
    this.username = username;
    this.passwordHash = passwordHash;
    this.salt = salt;
    this.nickname = nickname;
    this.avatar = avatar;
    this.createdAt = createdAt;
  }
}
