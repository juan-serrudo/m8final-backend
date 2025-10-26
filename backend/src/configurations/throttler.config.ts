import { ConfigService } from '@nestjs/config';
import { ThrottlerModuleOptions } from '@nestjs/throttler';
import { RedisStorage } from './redis-storage';

export const throttlerConfig = (configService: ConfigService, redisStorage: RedisStorage): ThrottlerModuleOptions => ({
  throttlers: [
    {
      ttl: (configService.get('throttler.ttl') || 60) * 1000, // Convertir a milisegundos
      limit: configService.get('throttler.limit') || 10,
    },
  ],
  storage: redisStorage,
});
