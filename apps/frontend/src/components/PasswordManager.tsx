import { useState } from 'react';
import { type PasswordEntry, type CreatePasswordEntry, type UpdatePasswordEntry, passwordManagerApi } from '../services/api';
import PasswordForm from './PasswordForm';
import PasswordList from './PasswordList';
import PasswordDecrypt from './PasswordDecrypt';

interface PasswordManagerProps {
  passwords: PasswordEntry[];
  loading: boolean;
  error: string | null;
  onRefresh: () => void;
}

const PasswordManager: React.FC<PasswordManagerProps> = ({
  passwords,
  loading,
  error,
  onRefresh
}) => {
  const [showForm, setShowForm] = useState(false);
  const [editingPassword, setEditingPassword] = useState<PasswordEntry | null>(null);
  const [decryptingPassword, setDecryptingPassword] = useState<PasswordEntry | null>(null);
  const [filter, setFilter] = useState<string>('all');

  const handleCreate = async (data: CreatePasswordEntry | UpdatePasswordEntry) => {
    try {
      const response = await passwordManagerApi.create(data as CreatePasswordEntry);
      if (response.success) {
        onRefresh();
        setShowForm(false);
      } else {
        alert(`Error: ${response.message}`);
      }
    } catch (err: any) {
      alert(`Error: ${err.response?.data?.message || err.message}`);
    }
  };

  const handleUpdate = async (id: number, data: CreatePasswordEntry | UpdatePasswordEntry) => {
    try {
      const response = await passwordManagerApi.update(id, data as UpdatePasswordEntry);
      if (response.success) {
        onRefresh();
        setEditingPassword(null);
      } else {
        alert(`Error: ${response.message}`);
      }
    } catch (err: any) {
      alert(`Error: ${err.response?.data?.message || err.message}`);
    }
  };

  const handleDelete = async (id: number, masterKey: string) => {
    if (!confirm('Are you sure you want to delete this password entry?')) {
      return;
    }

    try {
      const response = await passwordManagerApi.delete(id, masterKey);
      if (response.success) {
        onRefresh();
      } else {
        alert(`Error: ${response.message}`);
      }
    } catch (err: any) {
      alert(`Error: ${err.response?.data?.message || err.message}`);
    }
  };

  const filteredPasswords = filter === 'all'
    ? passwords
    : passwords.filter(p => p.category.toLowerCase() === filter.toLowerCase());

  const categories = Array.from(new Set(passwords.map(p => p.category)));

  return (
    <div className="password-manager">
      <div className="password-manager-header">
        <h2>Gestor de Contraseñas</h2>
        <div className="password-manager-controls">
          <button
            className="btn btn-primary"
            onClick={() => setShowForm(true)}
          >
            Agregar Nueva Contraseña
          </button>
          <button
            className="btn btn-secondary"
            onClick={onRefresh}
            disabled={loading}
          >
            {loading ? 'Cargando...' : 'Actualizar'}
          </button>
        </div>
      </div>

      {error && (
        <div className="error-message">
          <p>Error: {error}</p>
        </div>
      )}

      <div className="filter-section">
        <label htmlFor="category-filter">Filtrar por categoría:</label>
        <select
          id="category-filter"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="filter-select"
        >
          <option value="all">Todas las Categorías</option>
          {categories.map(category => (
            <option key={category} value={category}>{category}</option>
          ))}
        </select>
      </div>

      <PasswordList
        passwords={filteredPasswords}
        onEdit={setEditingPassword}
        onDelete={handleDelete}
        onDecrypt={setDecryptingPassword}
      />

      {showForm && (
        <PasswordForm
          onSubmit={handleCreate}
          onCancel={() => setShowForm(false)}
          title="Add New Password"
        />
      )}

      {editingPassword && (
        <PasswordForm
          password={editingPassword}
          onSubmit={(data) => handleUpdate(editingPassword.id, data)}
          onCancel={() => setEditingPassword(null)}
          title="Edit Password"
        />
      )}

      {decryptingPassword && (
        <PasswordDecrypt
          password={decryptingPassword}
          onClose={() => setDecryptingPassword(null)}
        />
      )}
    </div>
  );
};

export default PasswordManager;
