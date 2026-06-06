/**
 * 用户实体。passwordHash = SHA256(salt + 明文)，绝不存明文。
 */
export class User {
  id: number;
  username: string;
  passwordHash: string;
  salt: string;
  nickname: string;
  avatar: string;
  createdAt: string;

  constructor(id: number, username: string, passwordHash: string, salt: string,
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
