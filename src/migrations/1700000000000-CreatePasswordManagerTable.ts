import { MigrationInterface, QueryRunner, Table } from 'typeorm';

export class CreatePasswordManagerTable1700000000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: 'password_manager',
        columns: [
          {
            name: 'id',
            type: 'serial',
            isPrimary: true,
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
          {
            name: 'updateAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
            onUpdate: 'CURRENT_TIMESTAMP',
          },
          {
            name: 'version',
            type: 'int',
            default: 1,
          },
          {
            name: 'state',
            type: 'int2',
            default: 1,
          },
          {
            name: 'title',
            type: 'varchar',
            length: '200',
          },
          {
            name: 'description',
            type: 'varchar',
            length: '500',
          },
          {
            name: 'username',
            type: 'varchar',
            length: '200',
          },
          {
            name: 'encryptedPassword',
            type: 'text',
          },
          {
            name: 'url',
            type: 'varchar',
            length: '500',
          },
          {
            name: 'category',
            type: 'varchar',
            length: '200',
          },
          {
            name: 'notes',
            type: 'text',
          },
          {
            name: 'masterKeyHash',
            type: 'varchar',
            length: '500',
          },
        ],
      }),
      true,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('password_manager');
  }
}
