import { AppDataSource } from '../configurations/data-source';
import { SeedRunner } from '../seeds';

async function runMigrations() {
  try {
    console.log('Iniciando migraciones...');
    console.log('Conectando a:', process.env.DB_HOST, process.env.DB_NAME);
    await AppDataSource.initialize();
    console.log('Conexión establecida, ejecutando migraciones...');
    await AppDataSource.runMigrations();
    console.log('Migraciones ejecutadas exitosamente');
  } catch (error) {
    console.error('Error ejecutando migraciones:', error);
    process.exit(1);
  } finally {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
  }
}

async function runSeeds() {
  try {
    console.log('Iniciando seeds...');
    console.log('Conectando a:', process.env.DB_HOST, process.env.DB_NAME);
    await AppDataSource.initialize();
    console.log('Conexión establecida, ejecutando seeds...');
    const seedRunner = new SeedRunner(AppDataSource);
    await seedRunner.run();
    console.log('Seeds ejecutados exitosamente');
  } catch (error) {
    console.error('Error ejecutando seeds:', error);
    process.exit(1);
  } finally {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
  }
}

async function main() {
  const command = process.argv[2];

  switch (command) {
    case 'migrate':
      await runMigrations();
      break;
    case 'seed':
      await runSeeds();
      break;
    case 'all':
      await runMigrations();
      await runSeeds();
      break;
    default:
      console.log('Uso: npm run migrate:run | npm run seed:run | npm run migrate:all');
      process.exit(1);
  }
}

main();
