import { DataSource } from 'typeorm';
import { PasswordManager } from '../entitys/password-manager.entity';
import * as bcrypt from 'bcryptjs';
import * as CryptoJS from 'crypto-js';

export class PasswordManagerSeed {
  public async run(dataSource: DataSource): Promise<void> {
    const passwordManagerRepository = dataSource.getRepository(PasswordManager);

    // Verificar si ya existen datos
    const existingCount = await passwordManagerRepository.count();
    if (existingCount > 0) {
      console.log('PasswordManager seed ya ejecutado, saltando...');
      return;
    }

    // Crear master key hash
    const masterKey = 'master123';
    const masterKeyHash = await bcrypt.hash(masterKey, 10);

    // Datos de ejemplo
    const samplePasswords = [
      {
        title: 'Gmail Personal',
        description: 'Cuenta principal de Gmail',
        username: 'usuario@gmail.com',
        password: 'miPasswordSegura123',
        url: 'https://gmail.com',
        category: 'Email',
        notes: 'Cuenta principal para trabajo y personal',
      },
      {
        title: 'GitHub',
        description: 'Repositorios de código',
        username: 'developer',
        password: 'githubPassword456',
        url: 'https://github.com',
        category: 'Desarrollo',
        notes: 'Acceso a repositorios privados',
      },
      {
        title: 'Netflix',
        description: 'Suscripción de streaming',
        username: 'usuario@email.com',
        password: 'netflixPass789',
        url: 'https://netflix.com',
        category: 'Entretenimiento',
        notes: 'Cuenta familiar compartida',
      },
    ];

    for (const item of samplePasswords) {
      // Encriptar la contraseña usando AES
      const encryptedPassword = CryptoJS.AES.encrypt(item.password, masterKey).toString();

      const passwordEntry = passwordManagerRepository.create({
        title: item.title,
        description: item.description,
        username: item.username,
        encryptedPassword,
        url: item.url,
        category: item.category,
        notes: item.notes,
        masterKeyHash,
      });

      await passwordManagerRepository.save(passwordEntry);
    }

    console.log('PasswordManager seed ejecutado exitosamente');
  }
}
