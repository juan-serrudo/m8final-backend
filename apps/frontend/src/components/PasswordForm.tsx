import { useState, useEffect } from 'react';
import { type PasswordEntry, type CreatePasswordEntry, type UpdatePasswordEntry } from '../services/api';

interface PasswordFormProps {
  password?: PasswordEntry;
  onSubmit: (data: CreatePasswordEntry | UpdatePasswordEntry) => void;
  onCancel: () => void;
  title: string;
}

const PasswordForm: React.FC<PasswordFormProps> = ({
  password,
  onSubmit,
  onCancel,
  title
}) => {
  const [formData, setFormData] = useState({
    title: password?.title || '',
    username: password?.username || '',
    password: '',
    category: password?.category || '',
    masterKey: ''
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (password) {
      setFormData(prev => ({
        ...prev,
        title: password.title,
        username: password.username,
        category: password.category
      }));
    }
  }, [password]);

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.title.trim()) {
      newErrors.title = 'El título es requerido';
    }

    if (!formData.username.trim()) {
      newErrors.username = 'El nombre de usuario es requerido';
    }

    if (!password && !formData.password.trim()) {
      newErrors.password = 'La contraseña es requerida';
    }

    if (!formData.category.trim()) {
      newErrors.category = 'La categoría es requerida';
    }

    if (!formData.masterKey.trim()) {
      newErrors.masterKey = 'La clave maestra es requerida';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    const submitData = {
      title: formData.title.trim(),
      username: formData.username.trim(),
      category: formData.category.trim(),
      masterKey: formData.masterKey.trim(),
      ...(formData.password.trim() && { password: formData.password.trim() })
    };

    onSubmit(submitData);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));

    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal">
        <div className="modal-header">
          <h3>{title}</h3>
          <button className="close-btn" onClick={onCancel}>×</button>
        </div>

        <form onSubmit={handleSubmit} className="password-form">
          <div className="form-group">
            <label htmlFor="title">Título *</label>
            <input
              type="text"
              id="title"
              name="title"
              value={formData.title}
              onChange={handleChange}
              className={errors.title ? 'error' : ''}
              placeholder="Ejemplo Cuenta de Gmail"
            />
            {errors.title && <span className="error-text">{errors.title}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="username">Nombre de Usuario *</label>
            <input
              type="text"
              id="username"
              name="username"
              value={formData.username}
              onChange={handleChange}
              className={errors.username ? 'error' : ''}
              placeholder="Ejemplo: usuario@ejemplo.com"
            />
            {errors.username && <span className="error-text">{errors.username}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="password">
              Contraseña {!password && '*'}
            </label>
            <input
              type="password"
              id="password"
              name="password"
              value={formData.password}
              onChange={handleChange}
              className={errors.password ? 'error' : ''}
              placeholder={password ? "Dejar vacío para mantener la contraseña actual" : "Ingresar contraseña"}
            />
            {errors.password && <span className="error-text">{errors.password}</span>}
            {password && (
              <small className="form-help">
                Dejar vacío para mantener la contraseña actual
              </small>
            )}
          </div>

          <div className="form-group">
            <label htmlFor="category">Categoría *</label>
            <select
              id="category"
              name="category"
              value={formData.category}
              onChange={handleChange}
              className={errors.category ? 'error' : ''}
            >
              <option value="">Seleccionar una categoría</option>
              <option value="Redes Sociales">Redes Sociales</option>
              <option value="Email">Email</option>
              <option value="Bancario">Bancario</option>
              <option value="Trabajo">Trabajo</option>
              <option value="Personal">Personal</option>
              <option value="Juegos">Juegos</option>
              <option value="Compras">Compras</option>
              <option value="Otro">Otro</option>
            </select>
            {errors.category && <span className="error-text">{errors.category}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="masterKey">Clave Maestra *</label>
            <input
              type="password"
              id="masterKey"
              name="masterKey"
              value={formData.masterKey}
              onChange={handleChange}
              className={errors.masterKey ? 'error' : ''}
              placeholder="Ingresar tu clave maestra"
            />
            {errors.masterKey && <span className="error-text">{errors.masterKey}</span>}
            <small className="form-help">
              Esto es requerido para encriptar/desencriptar tu contraseña
            </small>
          </div>

          <div className="form-actions">
            <button type="button" onClick={onCancel} className="btn btn-secondary">
              Cancelar
            </button>
            <button type="submit" className="btn btn-primary">
              {password ? 'Actualizar' : 'Crear'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default PasswordForm;
