import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import {
  HealthCheckService,
  HealthCheck,
  TypeOrmHealthIndicator,
  MemoryHealthIndicator,
  DiskHealthIndicator,
} from '@nestjs/terminus';
import { CacheService } from '../services/cache.service';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private db: TypeOrmHealthIndicator,
    private memory: MemoryHealthIndicator,
    private disk: DiskHealthIndicator,
    private cacheService: CacheService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Health check general' })
  @ApiResponse({ status: 200, description: 'Estado general del sistema' })
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.memory.checkHeap('memory_heap', 150 * 1024 * 1024),
      () => this.memory.checkRSS('memory_rss', 150 * 1024 * 1024),
      () => this.disk.checkStorage('storage', { path: '/', thresholdPercent: 0.5 }),
    ]);
  }

  @Get('db')
  @ApiOperation({ summary: 'Health check de base de datos' })
  @ApiResponse({ status: 200, description: 'Estado de la base de datos' })
  @HealthCheck()
  checkDatabase() {
    return this.health.check([
      () => this.db.pingCheck('database'),
    ]);
  }

  @Get('redis')
  @ApiOperation({ summary: 'Health check de Redis' })
  @ApiResponse({ status: 200, description: 'Estado de Redis' })
  @HealthCheck()
  async checkRedis() {
    try {
      const ping = await this.cacheService.ping();
      return {
        status: 'ok',
        info: {
          redis: {
            status: 'up',
            ping: ping,
          },
        },
        error: {},
        details: {
          redis: {
            status: 'up',
            ping: ping,
          },
        },
      };
    } catch (error) {
      return {
        status: 'error',
        info: {
          redis: {
            status: 'down',
            error: error.message,
          },
        },
        error: {
          redis: {
            status: 'down',
            error: error.message,
          },
        },
        details: {
          redis: {
            status: 'down',
            error: error.message,
          },
        },
      };
    }
  }
}
