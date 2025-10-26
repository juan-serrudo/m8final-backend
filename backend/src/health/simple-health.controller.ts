import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Health')
@Controller('health')
export class SimpleHealthController {

  @Get()
  @ApiOperation({ summary: 'Health check general' })
  @ApiResponse({ status: 200, description: 'Estado general del sistema' })
  check() {
    return {
      status: 'ok',
      message: 'Sistema funcionando correctamente',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    };
  }

  @Get('db')
  @ApiOperation({ summary: 'Health check de base de datos' })
  @ApiResponse({ status: 200, description: 'Estado de la base de datos' })
  async checkDatabase() {
    try {
      const { Client } = require('pg');
      const client = new Client({
        host: process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.DB_PORT || '5432'),
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'password123',
        database: process.env.DB_NAME || 'password_manager',
      });

      await client.connect();
      await client.query('SELECT 1');
      await client.end();

      return {
        status: 'ok',
        info: {
          database: {
            status: 'up',
            message: 'PostgreSQL connection successful',
          },
        },
        error: {},
        details: {
          database: {
            status: 'up',
            message: 'PostgreSQL connection successful',
          },
        },
      };
    } catch (error) {
      return {
        status: 'error',
        info: {
          database: {
            status: 'down',
            error: error.message,
          },
        },
        error: {
          database: {
            status: 'down',
            error: error.message,
          },
        },
        details: {
          database: {
            status: 'down',
            error: error.message,
          },
        },
      };
    }
  }

  @Get('redis')
  @ApiOperation({ summary: 'Health check de Redis' })
  @ApiResponse({ status: 200, description: 'Estado de Redis' })
  async checkRedis() {
    try {
      const Redis = require('ioredis');
      const redis = new Redis({
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379'),
        password: process.env.REDIS_PASSWORD || undefined,
        db: parseInt(process.env.REDIS_DB || '0'),
      });

      const ping = await redis.ping();
      await redis.disconnect();

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
