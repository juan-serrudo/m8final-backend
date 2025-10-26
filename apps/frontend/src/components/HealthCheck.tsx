import { useState, useEffect } from 'react';
import api from '../services/api';

interface HealthStatus {
  status: string;
  info: Record<string, any>;
  error: Record<string, any>;
  details: Record<string, any>;
}

const HealthCheck: React.FC = () => {
  const [healthStatus, setHealthStatus] = useState<HealthStatus | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastChecked, setLastChecked] = useState<Date | null>(null);

  const checkHealth = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await api.get('/health');
      setHealthStatus(response.data);
      setLastChecked(new Date());
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Error al verificar el estado del sistema');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    checkHealth();
  }, []);

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'ok':
        return '#4CAF50';
      case 'error':
        return '#F44336';
      default:
        return '#FF9800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status.toLowerCase()) {
      case 'ok':
        return '✅';
      case 'error':
        return '❌';
      default:
        return '⚠️';
    }
  };

  const formatHealthInfo = (info: Record<string, any>) => {
    return Object.entries(info).map(([key, value]) => (
      <div key={key} className="health-info-item">
        <strong>{key}:</strong>
        <span className={`status-${value.status?.toLowerCase() || 'unknown'}`}>
          {getStatusIcon(value.status || 'unknown')} {value.status || 'Unknown'}
        </span>
        {value.details && (
          <div className="health-details">
            <small>{JSON.stringify(value.details, null, 2)}</small>
          </div>
        )}
      </div>
    ));
  };

  return (
    <div className="health-check">
      <div className="health-check-header">
        <h2>Verificación de Estado del Sistema</h2>
        <button 
          className="btn btn-primary" 
          onClick={checkHealth}
          disabled={loading}
        >
          {loading ? 'Verificando...' : 'Actualizar'}
        </button>
      </div>

      {lastChecked && (
        <div className="last-checked">
          Última verificación: {lastChecked.toLocaleString()}
        </div>
      )}

      {error && (
        <div className="error-message">
          <h3>❌ Error</h3>
          <p>{error}</p>
        </div>
      )}

      {healthStatus && (
        <div className="health-status">
          <div className="overall-status">
            <h3>
              Estado General: 
              <span 
                className="status-indicator"
                style={{ color: getStatusColor(healthStatus.status) }}
              >
                {getStatusIcon(healthStatus.status)} {healthStatus.status.toUpperCase()}
              </span>
            </h3>
          </div>

          {healthStatus.info && Object.keys(healthStatus.info).length > 0 && (
            <div className="health-info">
              <h4>Información del Sistema</h4>
              {formatHealthInfo(healthStatus.info)}
            </div>
          )}

          {healthStatus.error && Object.keys(healthStatus.error).length > 0 && (
            <div className="health-errors">
              <h4>Errores</h4>
              {formatHealthInfo(healthStatus.error)}
            </div>
          )}

          {healthStatus.details && Object.keys(healthStatus.details).length > 0 && (
            <div className="health-details">
              <h4>Detalles Adicionales</h4>
              <pre>{JSON.stringify(healthStatus.details, null, 2)}</pre>
            </div>
          )}
        </div>
      )}

      <div className="health-info-section">
        <h3>Acerca de las Verificaciones de Salud</h3>
        <p>
          Esta verificación de salud monitorea el estado de varios componentes del sistema incluyendo:
        </p>
        <ul>
          <li><strong>Base de Datos:</strong> Conexión PostgreSQL y rendimiento de consultas</li>
          <li><strong>Caché:</strong> Conexión Redis y uso de memoria</li>
          <li><strong>API:</strong> Disponibilidad del servicio backend</li>
          <li><strong>Memoria:</strong> Uso de memoria del sistema y estadísticas del heap</li>
        </ul>
      </div>
    </div>
  );
};

export default HealthCheck;
