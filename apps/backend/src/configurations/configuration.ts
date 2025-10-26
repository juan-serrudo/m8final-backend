import { join } from 'path';

export default () => {
  const locatePackagejson = process.cwd();
  let pm2 = false;
  if (locatePackagejson.includes('dist')) {
    pm2 = true;
  }

  return {
    packageJson: require(join(process.cwd(), pm2 ? '../package.json' : 'package.json')),
    port: process.env.PORT || 3000,
    appMaxSize: process.env.APP_MAX_SIZE || '10mb',
    ENV_ENTORNO: process.env.ENV_ENTORNO || 'dev',
    ENV_CORS: process.env.ENV_CORS || '',
    ENV_SWAGGER_SHOW: process.env.ENV_SWAGGER_SHOW === 'true' || false,
    ENV_SYNCHRONIZE: process.env.ENV_SYNCHRONIZE === 'true' || false,
    
    // Database configuration
    database: {
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      username: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'password',
      database: process.env.DB_NAME || 'password_manager',
      synchronize: process.env.NODE_ENV === 'development',
      logging: process.env.NODE_ENV === 'development',
      ssl: false,
    },
    
    // Redis configuration
    redis: {
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD || undefined,
      db: parseInt(process.env.REDIS_DB || '0'),
    },
    
    // Throttler configuration
    throttler: {
      ttl: parseInt(process.env.THROTTLE_TTL || '60'),
      limit: parseInt(process.env.THROTTLE_LIMIT || '10'),
    },
  };
};
