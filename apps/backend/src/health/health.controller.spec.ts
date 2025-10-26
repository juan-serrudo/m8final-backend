import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';
import { HealthCheckService, TypeOrmHealthIndicator, MemoryHealthIndicator, DiskHealthIndicator } from '@nestjs/terminus';
import { CacheService } from '../services/cache.service';

describe('HealthController', () => {
  let controller: HealthController;
  let healthCheckService: HealthCheckService;
  let cacheService: CacheService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        {
          provide: HealthCheckService,
          useValue: {
            check: jest.fn(),
          },
        },
        {
          provide: TypeOrmHealthIndicator,
          useValue: {
            pingCheck: jest.fn(),
          },
        },
        {
          provide: MemoryHealthIndicator,
          useValue: {
            checkHeap: jest.fn(),
            checkRSS: jest.fn(),
          },
        },
        {
          provide: DiskHealthIndicator,
          useValue: {
            checkStorage: jest.fn(),
          },
        },
        {
          provide: CacheService,
          useValue: {
            ping: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<HealthController>(HealthController);
    healthCheckService = module.get<HealthCheckService>(HealthCheckService);
    cacheService = module.get<CacheService>(CacheService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('check', () => {
    it('should return health check result', async () => {
      const mockResult = {
        status: 'ok',
        info: {},
        error: {},
        details: {},
      };

      jest.spyOn(healthCheckService, 'check').mockResolvedValue(mockResult);

      const result = await controller.check();

      expect(result).toEqual(mockResult);
      expect(healthCheckService.check).toHaveBeenCalled();
    });
  });

  describe('checkDatabase', () => {
    it('should return database health check result', async () => {
      const mockResult = {
        status: 'ok',
        info: { database: { status: 'up' } },
        error: {},
        details: { database: { status: 'up' } },
      };

      jest.spyOn(healthCheckService, 'check').mockResolvedValue(mockResult);

      const result = await controller.checkDatabase();

      expect(result).toEqual(mockResult);
      expect(healthCheckService.check).toHaveBeenCalled();
    });
  });

  describe('checkRedis', () => {
    it('should return Redis health check result when Redis is available', async () => {
      jest.spyOn(cacheService, 'ping').mockResolvedValue('PONG');

      const result = await controller.checkRedis();

      expect(result.status).toBe('ok');
      expect(result.info.redis.status).toBe('up');
      expect(result.info.redis.ping).toBe('PONG');
    });

    it('should return error status when Redis is unavailable', async () => {
      const error = new Error('Connection failed');
      jest.spyOn(cacheService, 'ping').mockRejectedValue(error);

      const result = await controller.checkRedis();

      expect(result.status).toBe('error');
      expect(result.error.redis.status).toBe('down');
      expect(result.error.redis.error).toBe('Connection failed');
    });
  });
});
