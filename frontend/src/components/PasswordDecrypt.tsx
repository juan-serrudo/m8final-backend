import React, { useState } from 'react';
import { PasswordEntry, passwordManagerApi } from '../services/api';

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
      setError('Master key is required');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await passwordManagerApi.decrypt(password.id, { masterKey });
      
      if (response.success && response.data) {
        setDecryptedPassword(response.data.decryptedPassword);
      } else {
        setError(response.message || 'Failed to decrypt password');
      }
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Failed to decrypt password');
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text).then(() => {
      alert('Password copied to clipboard!');
    }).catch(() => {
      alert('Failed to copy to clipboard');
    });
  };

  const getCategoryIcon = (category: string) => {
    const icons: Record<string, string> = {
      'Social Media': '📱',
      'Email': '📧',
      'Banking': '🏦',
      'Work': '💼',
      'Personal': '👤',
      'Gaming': '🎮',
      'Shopping': '🛒',
      'Other': '🔐'
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
              <label>Username:</label>
              <span>{password.username}</span>
            </div>
            <div className="info-field">
              <label>Category:</label>
              <span>{password.category}</span>
            </div>
          </div>

          {!decryptedPassword ? (
            <form onSubmit={handleDecrypt} className="decrypt-form">
              <div className="form-group">
                <label htmlFor="masterKey">Master Key</label>
                <input
                  type="password"
                  id="masterKey"
                  value={masterKey}
                  onChange={(e) => setMasterKey(e.target.value)}
                  placeholder="Enter your master key"
                  className={error ? 'error' : ''}
                  disabled={loading}
                />
                {error && <span className="error-text">{error}</span>}
              </div>

              <div className="form-actions">
                <button type="button" onClick={onClose} className="btn btn-secondary">
                  Cancel
                </button>
                <button 
                  type="submit" 
                  className="btn btn-primary"
                  disabled={loading}
                >
                  {loading ? 'Decrypting...' : 'Decrypt Password'}
                </button>
              </div>
            </form>
          ) : (
            <div className="decrypted-password">
              <div className="form-group">
                <label>Decrypted Password:</label>
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
                    📋 Copy
                  </button>
                </div>
              </div>

              <div className="form-actions">
                <button onClick={onClose} className="btn btn-primary">
                  Close
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
