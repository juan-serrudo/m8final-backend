import { DataSource } from 'typeorm';
import { PasswordManagerSeed } from './PasswordManagerSeed';

export class SeedRunner {
  constructor(private dataSource: DataSource) {}

  async run(): Promise<void> {
    console.log('Iniciando seeds...');

    try {
      // Ejecutar seeds
      const passwordManagerSeed = new PasswordManagerSeed();
      await passwordManagerSeed.run(this.dataSource);

      console.log('Todos los seeds ejecutados exitosamente');
    } catch (error) {
      console.error('Error ejecutando seeds:', error);
      throw error;
    }
  }
}
