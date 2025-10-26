import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import PasswordManager from '../PasswordManager';

// Mock the API
jest.mock('../../services/api', () => ({
  passwordManagerApi: {
    getAll: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    decrypt: jest.fn(),
  },
}));

const mockPasswords = [
  {
    id: 1,
    title: 'Test Password',
    username: 'test@example.com',
    category: 'Email',
    encryptedPassword: 'encrypted_data',
    createdAt: '2024-01-01T00:00:00Z',
    updatedAt: '2024-01-01T00:00:00Z',
  },
];

describe('PasswordManager', () => {
  const mockOnRefresh = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders password manager with empty state', () => {
    render(
      <PasswordManager
        passwords={[]}
        loading={false}
        error={null}
        onRefresh={mockOnRefresh}
      />
    );

    expect(screen.getByText('Password Manager')).toBeInTheDocument();
    expect(screen.getByText('No passwords found')).toBeInTheDocument();
  });

  it('renders password list when passwords are available', () => {
    render(
      <PasswordManager
        passwords={mockPasswords}
        loading={false}
        error={null}
        onRefresh={mockOnRefresh}
      />
    );

    expect(screen.getByText('Test Password')).toBeInTheDocument();
    expect(screen.getByText('test@example.com')).toBeInTheDocument();
    expect(screen.getByText('Email')).toBeInTheDocument();
  });

  it('shows loading state', () => {
    render(
      <PasswordManager
        passwords={[]}
        loading={true}
        error={null}
        onRefresh={mockOnRefresh}
      />
    );

    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  it('shows error message when there is an error', () => {
    const errorMessage = 'Failed to load passwords';
    render(
      <PasswordManager
        passwords={[]}
        loading={false}
        error={errorMessage}
        onRefresh={mockOnRefresh}
      />
    );

    expect(screen.getByText(`Error: ${errorMessage}`)).toBeInTheDocument();
  });

  it('calls onRefresh when refresh button is clicked', () => {
    render(
      <PasswordManager
        passwords={[]}
        loading={false}
        error={null}
        onRefresh={mockOnRefresh}
      />
    );

    const refreshButton = screen.getByText('Refresh');
    fireEvent.click(refreshButton);

    expect(mockOnRefresh).toHaveBeenCalledTimes(1);
  });

  it('opens form when add new password button is clicked', () => {
    render(
      <PasswordManager
        passwords={[]}
        loading={false}
        error={null}
        onRefresh={mockOnRefresh}
      />
    );

    const addButton = screen.getByText('Add New Password');
    fireEvent.click(addButton);

    expect(screen.getByText('Add New Password')).toBeInTheDocument();
  });
});
