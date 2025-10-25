import { Module } from '@nestjs/common';
import { TerminusModule } from '@nestjs/terminus';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HealthController } from './health.controller';
import { CacheService } from '../services/cache.service';
import { redisProviders } from '../providers/redis.providers';

@Module({
  imports: [
    TerminusModule,
    TypeOrmModule.forRoot(),
  ],
  controllers: [HealthController],
  providers: [CacheService, ...redisProviders],
})
export class HealthModule {}
