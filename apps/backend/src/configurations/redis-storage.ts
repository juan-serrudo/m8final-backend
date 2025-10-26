import { Injectable } from '@nestjs/common';
import { Inject } from '@nestjs/common';
import { REDIS_CLIENT } from '../providers/redis.providers';
import { ThrottlerStorage } from '@nestjs/throttler';
import Redis from 'ioredis';

@Injectable()
export class RedisStorage implements ThrottlerStorage {
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

  async increment(key: string, ttl: number, limit: number, blockDuration: number, throttlerName: string): Promise<any> {
    const current = await this.redis.get(key);
    const count = current ? parseInt(current) : 0;
    
    if (count >= limit) {
      return {
        totalHits: count,
        timeToExpire: ttl,
        isBlocked: true,
        blockExpires: Date.now() + blockDuration,
      };
    }
    
    const newCount = count + 1;
    await this.redis.setex(key, Math.ceil(ttl / 1000), newCount.toString());
    
    return {
      totalHits: newCount,
      timeToExpire: ttl,
      isBlocked: false,
      blockExpires: 0,
    };
  }
}
