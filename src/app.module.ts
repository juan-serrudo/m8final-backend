import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';
import configuration from './configurations/configuration';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PasswordManagerController } from './modules/password-manager/password-manager.controller';
import { PasswordManagerService } from './modules/password-manager/password-manager.service';
import { databaseProviders } from './providers/database.providers';
import { passwordManagerProviders } from './providers/password-manager.providers';
import { redisProviders } from './providers/redis.providers';
import { CacheService } from './services/cache.service';
import { HealthModule } from './health/health.module';
import { PasswordManager } from './entitys/password-manager.entity';
import { throttlerConfig } from './configurations/throttler.config';
import { RedisStorage } from './configurations/redis-storage';

@Module({
  imports: [
    ConfigModule.forRoot({
      load: [configuration],
      expandVariables: true,
      isGlobal: true
    }),
    TypeOrmModule.forRootAsync({
      useFactory: (configService) => ({
        type: 'postgres',
        host: configService.get('database.host'),
        port: configService.get('database.port'),
        username: configService.get('database.username'),
        password: configService.get('database.password'),
        database: configService.get('database.database'),
        entities: [PasswordManager],
        synchronize: configService.get('database.synchronize'),
        logging: configService.get('database.logging'),
        ssl: configService.get('database.ssl'),
      }),
      inject: [ConfigService],
    }),
    TypeOrmModule.forFeature([PasswordManager]),
    ThrottlerModule.forRootAsync({
      useFactory: (configService, redisStorage) => throttlerConfig(configService, redisStorage),
      inject: [ConfigService, RedisStorage],
    }),
    HealthModule,
  ],
  controllers: [
    AppController,
    PasswordManagerController,
  ],
  providers: [
    AppService,
    PasswordManagerService,
    CacheService,
    RedisStorage,
    ...databaseProviders,
    ...passwordManagerProviders,
    ...redisProviders,
  ],
  exports: [
    ...databaseProviders,
    ...passwordManagerProviders,
    ...redisProviders,
  ],
})

export class AppModule {}
