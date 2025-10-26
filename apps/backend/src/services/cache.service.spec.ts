import { Test, TestingModule } from '@nestjs/testing';
import { CacheService } from './cache.service';
import { REDIS_CLIENT } from '../providers/redis.providers';

describe('CacheService', () => {
  let service: CacheService;
  let mockRedis: any;

  beforeEach(async () => {
    mockRedis = {
      get: jest.fn(),
      setex: jest.fn(),
      del: jest.fn(),
      keys: jest.fn(),
      flushall: jest.fn(),
      ping: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CacheService,
        {
          provide: REDIS_CLIENT,
          useValue: mockRedis,
        },
      ],
    }).compile();

    service = module.get<CacheService>(CacheService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('get', () => {
    it('should return cached data when key exists', async () => {
      const testData = { id: 1, name: 'test' };
      mockRedis.get.mockResolvedValue(JSON.stringify(testData));

      const result = await service.get('test-key');

      expect(result).toEqual(testData);
      expect(mockRedis.get).toHaveBeenCalledWith('test-key');
    });

    it('should return null when key does not exist', async () => {
      mockRedis.get.mockResolvedValue(null);

      const result = await service.get('non-existent-key');

      expect(result).toBeNull();
    });

    it('should handle errors gracefully', async () => {
      mockRedis.get.mockRejectedValue(new Error('Redis error'));

      const result = await service.get('error-key');

      expect(result).toBeNull();
    });
  });

  describe('set', () => {
    it('should set data with TTL', async () => {
      const testData = { id: 1, name: 'test' };
      const ttl = 300;

      await service.set('test-key', testData, ttl);

      expect(mockRedis.setex).toHaveBeenCalledWith(
        'test-key',
        ttl,
        JSON.stringify(testData),
      );
    });

    it('should handle errors gracefully', async () => {
      mockRedis.setex.mockRejectedValue(new Error('Redis error'));

      await service.set('error-key', 'test-data', 300);

      // Should not throw
      expect(mockRedis.setex).toHaveBeenCalled();
    });
  });

  describe('del', () => {
    it('should delete key', async () => {
      await service.del('test-key');

      expect(mockRedis.del).toHaveBeenCalledWith('test-key');
    });

    it('should handle errors gracefully', async () => {
      mockRedis.del.mockRejectedValue(new Error('Redis error'));

      await service.del('error-key');

      // Should not throw
      expect(mockRedis.del).toHaveBeenCalled();
    });
  });

  describe('ping', () => {
    it('should return pong when Redis is available', async () => {
      mockRedis.ping.mockResolvedValue('PONG');

      const result = await service.ping();

      expect(result).toBe('PONG');
    });

    it('should throw error when Redis is unavailable', async () => {
      mockRedis.ping.mockRejectedValue(new Error('Connection failed'));

      await expect(service.ping()).rejects.toThrow('Connection failed');
    });
  });
});
