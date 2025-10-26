import React, { useState, useEffect } from 'react';
import { PasswordEntry, CreatePasswordEntry, UpdatePasswordEntry } from '../services/api';

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
      newErrors.title = 'Title is required';
    }

    if (!formData.username.trim()) {
      newErrors.username = 'Username is required';
    }

    if (!password && !formData.password.trim()) {
      newErrors.password = 'Password is required';
    }

    if (!formData.category.trim()) {
      newErrors.category = 'Category is required';
    }

    if (!formData.masterKey.trim()) {
      newErrors.masterKey = 'Master key is required';
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
            <label htmlFor="title">Title *</label>
            <input
              type="text"
              id="title"
              name="title"
              value={formData.title}
              onChange={handleChange}
              className={errors.title ? 'error' : ''}
              placeholder="e.g., Gmail Account"
            />
            {errors.title && <span className="error-text">{errors.title}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="username">Username *</label>
            <input
              type="text"
              id="username"
              name="username"
              value={formData.username}
              onChange={handleChange}
              className={errors.username ? 'error' : ''}
              placeholder="e.g., user@example.com"
            />
            {errors.username && <span className="error-text">{errors.username}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="password">
              Password {!password && '*'}
            </label>
            <input
              type="password"
              id="password"
              name="password"
              value={formData.password}
              onChange={handleChange}
              className={errors.password ? 'error' : ''}
              placeholder={password ? "Leave empty to keep current password" : "Enter password"}
            />
            {errors.password && <span className="error-text">{errors.password}</span>}
            {password && (
              <small className="form-help">
                Leave empty to keep the current password
              </small>
            )}
          </div>

          <div className="form-group">
            <label htmlFor="category">Category *</label>
            <select
              id="category"
              name="category"
              value={formData.category}
              onChange={handleChange}
              className={errors.category ? 'error' : ''}
            >
              <option value="">Select a category</option>
              <option value="Social Media">Social Media</option>
              <option value="Email">Email</option>
              <option value="Banking">Banking</option>
              <option value="Work">Work</option>
              <option value="Personal">Personal</option>
              <option value="Gaming">Gaming</option>
              <option value="Shopping">Shopping</option>
              <option value="Other">Other</option>
            </select>
            {errors.category && <span className="error-text">{errors.category}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="masterKey">Master Key *</label>
            <input
              type="password"
              id="masterKey"
              name="masterKey"
              value={formData.masterKey}
              onChange={handleChange}
              className={errors.masterKey ? 'error' : ''}
              placeholder="Enter your master key"
            />
            {errors.masterKey && <span className="error-text">{errors.masterKey}</span>}
            <small className="form-help">
              This is required to encrypt/decrypt your password
            </small>
          </div>

          <div className="form-actions">
            <button type="button" onClick={onCancel} className="btn btn-secondary">
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              {password ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default PasswordForm;
