import { useState } from 'react';
import { type PasswordEntry, passwordManagerApi } from '../services/api';

interface PasswordDecryptProps {
  password: PasswordEntry;
  onClose: () => void;
}

const PasswordDecrypt: React.FC<PasswordDecryptProps> = ({ password, onClose }) => {
  const [masterKey, setMasterKey] = useState('');
  const [decryptedPassword, setDecryptedPassword] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);

  const handleDecrypt = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!masterKey.trim()) {
      setError('La clave maestra es requerida');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await passwordManagerApi.decrypt(password.id, { masterKey });
      
      if (response.success && response.data) {
        setDecryptedPassword(response.data.decryptedPassword);
      } else {
        setError(response.message || 'Error al desencriptar la contraseña');
      }
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Error al desencriptar la contraseña');
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text).then(() => {
      alert('¡Contraseña copiada al portapapeles!');
    }).catch(() => {
      alert('Error al copiar al portapapeles');
    });
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

  return (
    <div className="modal-overlay">
      <div className="modal">
        <div className="modal-header">
          <h3>
            <span className="category-icon">{getCategoryIcon(password.category)}</span>
            {password.title}
          </h3>
          <button className="close-btn" onClick={onClose}>×</button>
        </div>

        <div className="password-decrypt">
          <div className="password-info">
            <div className="info-field">
              <label>Usuario:</label>
              <span>{password.username}</span>
            </div>
            <div className="info-field">
              <label>Categoría:</label>
              <span>{password.category}</span>
            </div>
          </div>

          {!decryptedPassword ? (
            <form onSubmit={handleDecrypt} className="decrypt-form">
              <div className="form-group">
                <label htmlFor="masterKey">Clave Maestra</label>
                <input
                  type="password"
                  id="masterKey"
                  value={masterKey}
                  onChange={(e) => setMasterKey(e.target.value)}
                  placeholder="Ingresa tu clave maestra"
                  className={error ? 'error' : ''}
                  disabled={loading}
                />
                {error && <span className="error-text">{error}</span>}
              </div>

              <div className="form-actions">
                <button type="button" onClick={onClose} className="btn btn-secondary">
                  Cancelar
                </button>
                <button 
                  type="submit" 
                  className="btn btn-primary"
                  disabled={loading}
                >
                  {loading ? 'Desencriptando...' : 'Desencriptar Contraseña'}
                </button>
              </div>
            </form>
          ) : (
            <div className="decrypted-password">
              <div className="form-group">
                <label>Contraseña Desencriptada:</label>
                <div className="password-display">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={decryptedPassword}
                    readOnly
                    className="password-input"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="btn btn-sm btn-secondary"
                  >
                    {showPassword ? '🙈' : '👁️'}
                  </button>
                  <button
                    type="button"
                    onClick={() => copyToClipboard(decryptedPassword)}
                    className="btn btn-sm btn-primary"
                  >
                    📋 Copiar
                  </button>
                </div>
              </div>

              <div className="form-actions">
                <button onClick={onClose} className="btn btn-primary">
                  Cerrar
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default PasswordDecrypt;
