import axios from 'axios';

// Base URL configuration - uses relative path in production, VITE_API_BASE_URL in development
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for logging
api.interceptors.request.use(
  (config) => {
    console.log(`Making ${config.method?.toUpperCase()} request to: ${config.url}`);
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    console.error('API Error:', error.response?.data || error.message);
    return Promise.reject(error);
  }
);

export interface PasswordEntry {
  id: number;
  title: string;
  username: string;
  category: string;
  encryptedPassword: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreatePasswordEntry {
  title: string;
  username: string;
  password: string;
  category: string;
  masterKey: string;
}

export interface UpdatePasswordEntry {
  title?: string;
  username?: string;
  password?: string;
  category?: string;
  masterKey: string;
}

export interface DecryptPasswordRequest {
  masterKey: string;
}

export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  error?: string;
}

export const passwordManagerApi = {
  // Get all password entries
  getAll: async (): Promise<ApiResponse<PasswordEntry[]>> => {
    const response = await api.get('/password-manager/');
    return response.data;
  },

  // Get password entry by ID
  getById: async (id: number): Promise<ApiResponse<PasswordEntry>> => {
    const response = await api.get(`/password-manager/${id}`);
    return response.data;
  },

  // Get password entries by category
  getByCategory: async (category: string): Promise<ApiResponse<PasswordEntry[]>> => {
    const response = await api.get(`/password-manager/category/${category}`);
    return response.data;
  },

  // Create new password entry
  create: async (data: CreatePasswordEntry): Promise<ApiResponse<PasswordEntry>> => {
    const response = await api.post('/password-manager/', data);
    return response.data;
  },

  // Update password entry
  update: async (id: number, data: UpdatePasswordEntry): Promise<ApiResponse<PasswordEntry>> => {
    const response = await api.put(`/password-manager/${id}`, data);
    return response.data;
  },

  // Delete password entry
  delete: async (id: number, masterKey: string): Promise<ApiResponse> => {
    const response = await api.delete(`/password-manager/${id}?masterKey=${encodeURIComponent(masterKey)}`);
    return response.data;
  },

  // Decrypt password
  decrypt: async (id: number, data: DecryptPasswordRequest): Promise<ApiResponse<{ decryptedPassword: string }>> => {
    const response = await api.post(`/password-manager/${id}/decrypt`, data);
    return response.data;
  },
};

export default api;
