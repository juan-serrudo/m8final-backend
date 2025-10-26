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
      setError(err.response?.data?.message || err.message || 'Failed to check health status');
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
        <h2>System Health Check</h2>
        <button 
          className="btn btn-primary" 
          onClick={checkHealth}
          disabled={loading}
        >
          {loading ? 'Checking...' : 'Refresh'}
        </button>
      </div>

      {lastChecked && (
        <div className="last-checked">
          Last checked: {lastChecked.toLocaleString()}
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
              Overall Status: 
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
              <h4>System Information</h4>
              {formatHealthInfo(healthStatus.info)}
            </div>
          )}

          {healthStatus.error && Object.keys(healthStatus.error).length > 0 && (
            <div className="health-errors">
              <h4>Errors</h4>
              {formatHealthInfo(healthStatus.error)}
            </div>
          )}

          {healthStatus.details && Object.keys(healthStatus.details).length > 0 && (
            <div className="health-details">
              <h4>Additional Details</h4>
              <pre>{JSON.stringify(healthStatus.details, null, 2)}</pre>
            </div>
          )}
        </div>
      )}

      <div className="health-info-section">
        <h3>About Health Checks</h3>
        <p>
          This health check monitors the status of various system components including:
        </p>
        <ul>
          <li><strong>Database:</strong> PostgreSQL connection and query performance</li>
          <li><strong>Cache:</strong> Redis connection and memory usage</li>
          <li><strong>API:</strong> Backend service availability</li>
          <li><strong>Memory:</strong> System memory usage and heap statistics</li>
        </ul>
      </div>
    </div>
  );
};

export default HealthCheck;
