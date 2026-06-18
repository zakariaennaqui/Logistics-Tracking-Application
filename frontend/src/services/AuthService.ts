import axios from 'axios';
import type { LoginRequest, RegisterRequest } from '../types/authTypes/auth';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8888';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: false, // This is crucial for CORS with authentication
});

export const authService = {
  register: async (userData: RegisterRequest) => {
    try {
      // const response = await api.post('/api/auth/register', userData, {
      //   withCredentials: true
      // });
      const response = await api.post('/api/auth/register', userData);
      return response.data;
    } catch (error: any) {
      console.error("Register error:", error);
      throw new Error(error.response?.data?.message || "Registration failed");
    }
  },

  login: async (credentials: LoginRequest) => {
    try {
      const response = await api.post('/api/auth/login', credentials, {
        withCredentials: true
      });
      return response.data;
    } catch (error: any) {
      console.error("Login error:", error);
      throw new Error(error.response?.data?.message || "Invalid credentials");
    }
  },
};

// Request interceptor
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    // Ensure credentials are included for all requests
    config.withCredentials = false;
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor to handle tokens
api.interceptors.response.use(
  (response) => {
    // If your backend returns token in response, you can store it here
    if (response.data.token) {
      localStorage.setItem('token', response.data.token);
    }
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized - clear token and redirect to login
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;