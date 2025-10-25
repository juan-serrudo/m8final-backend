import { Injectable } from '@nestjs/common';
import { Inject } from '@nestjs/common';
import { REDIS_CLIENT } from '../providers/redis.providers';
import Redis from 'ioredis';

@Injectable()
export class RedisStorage {
  constructor(@Inject(REDIS_CLIENT) private readonly redis: Redis) {}

  async get(key: string): Promise<string | null> {
    return await this.redis.get(key);
  }

  async set(key: string, value: string, ttl: number): Promise<void> {
    await this.redis.setex(key, Math.ceil(ttl / 1000), value);
  }

  async del(key: string): Promise<void> {
    await this.redis.del(key);
  }
}
