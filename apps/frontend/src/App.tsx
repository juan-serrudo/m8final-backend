import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import './App.css';
import PasswordManager from './components/PasswordManager';
import HealthCheck from './components/HealthCheck';
import { passwordManagerApi, type PasswordEntry } from './services/api';

function App() {
  const [passwords, setPasswords] = useState<PasswordEntry[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadPasswords = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await passwordManagerApi.getAll();
      if (response.success) {
        setPasswords(response.data || []);
      } else {
        setError(response.message || 'Error al cargar contraseñas');
      }
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Error al cargar las contraseñas');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPasswords();
  }, []);

  return (
    <Router>
      <div className="App">
        <header className="App-header">
          <nav className="navbar">
            <div className="nav-brand">
              <h1>🔐 Gestor de Contraseñas</h1>
            </div>
            <div className="nav-links">
              <Link to="/" className="nav-link">Inicio</Link>
              <Link to="/health" className="nav-link">Estado del Sistema</Link>
            </div>
          </nav>
        </header>

        <main className="App-main">
          <Routes>
            <Route
              path="/"
              element={
                <PasswordManager
                  passwords={passwords}
                  loading={loading}
                  error={error}
                  onRefresh={loadPasswords}
                />
              }
            />
            <Route path="/health" element={<HealthCheck />} />
          </Routes>
        </main>

        <footer className="App-footer">
          <p>Gestor de Contraseñas - Sistema Seguro de Gestión de Contraseñas</p>
        </footer>
      </div>
    </Router>
  );
}

export default App;