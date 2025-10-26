import { type PasswordEntry } from '../services/api';

interface PasswordListProps {
  passwords: PasswordEntry[];
  onEdit: (password: PasswordEntry) => void;
  onDelete: (id: number, masterKey: string) => void;
  onDecrypt: (password: PasswordEntry) => void;
}

const PasswordList: React.FC<PasswordListProps> = ({ 
  passwords, 
  onEdit, 
  onDelete, 
  onDecrypt 
}) => {
  const handleDelete = (password: PasswordEntry) => {
    const masterKey = prompt('Ingresa tu clave maestra para eliminar esta contraseña:');
    if (masterKey) {
      onDelete(password.id, masterKey);
    }
  };

  const getCategoryIcon = (category: string) => {
    const icons: Record<string, string> = {
      'Redes Sociales': '📱',
      'Email': '📧',
      'Bancario': '🏦',
      'Trabajo': '💼',
      'Personal': '👤',
      'Juegos': '🎮',
      'Compras': '🛒',
      'Otro': '🔐'
    };
    return icons[category] || '🔐';
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('es-ES', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (passwords.length === 0) {
    return (
      <div className="empty-state">
        <div className="empty-icon">🔐</div>
        <h3>No se encontraron contraseñas</h3>
        <p>Comienza agregando tu primera entrada de contraseña.</p>
      </div>
    );
  }

  return (
    <div className="password-list">
      <div className="password-grid">
        {passwords.map((password) => (
          <div key={password.id} className="password-card">
            <div className="password-card-header">
              <div className="password-title">
                <span className="category-icon">
                  {getCategoryIcon(password.category)}
                </span>
                <h4>{password.title}</h4>
              </div>
              <div className="password-category">
                {password.category}
              </div>
            </div>

            <div className="password-card-body">
              <div className="password-field">
                <label>Usuario:</label>
                <span className="password-value">{password.username}</span>
              </div>
              
              <div className="password-field">
                <label>Contraseña:</label>
                <span className="password-value password-masked">
                  {'•'.repeat(12)}
                </span>
              </div>

              <div className="password-meta">
                <small>Creado: {formatDate(password.createdAt)}</small>
                {password.updatedAt !== password.createdAt && (
                  <small>Actualizado: {formatDate(password.updatedAt)}</small>
                )}
              </div>
            </div>

            <div className="password-card-actions">
              <button 
                className="btn btn-sm btn-primary"
                onClick={() => onDecrypt(password)}
                title="Ver Contraseña"
              >
                👁️ Ver
              </button>
              
              <button 
                className="btn btn-sm btn-secondary"
                onClick={() => onEdit(password)}
                title="Editar Contraseña"
              >
                ✏️ Editar
              </button>
              
              <button 
                className="btn btn-sm btn-danger"
                onClick={() => handleDelete(password)}
                title="Eliminar Contraseña"
              >
                🗑️ Eliminar
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PasswordList;
