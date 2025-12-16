@extends('layouts.admin')

@section('content')
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h1 class="h3 mb-0">System Settings</h1>
                <div>
                    <button class="btn btn-outline-secondary" onclick="location.reload()">
                        <i class="fas fa-sync-alt me-2"></i>Refresh
                    </button>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-12">
            @if(session('success'))
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    {{ session('success') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            @endif

            @if(session('error'))
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    {{ session('error') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            @endif

            <div class="card">
                <div class="card-header">
                    <h5 class="card-title mb-0">
                        <i class="fas fa-cog me-2"></i>Platform Configuration
                    </h5>
                </div>
                <div class="card-body">
                    <div id="config-container">
                        <!-- Configuration will be loaded here -->
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
    function renderConfigTable(configs) {
        if (!configs || configs.length === 0) {
            return `
                <div class="text-center py-8">
                    <i class="fas fa-cog text-gray-400 text-4xl mb-4"></i>
                    <p class="text-gray-500">No configurations found</p>
                </div>
            `;
        }

        return `
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>Configuration</th>
                            <th>Current Value</th>
                            <th>Description</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${configs.map(config => `
                            <tr>
                                <td>
                                    <strong>${config.config_key.charAt(0).toUpperCase() + config.config_key.slice(1).replace(/_/g, ' ')}</strong>
                                </td>
                                <td>
                                    <span class="badge bg-primary">${config.config_value}</span>
                                </td>
                                <td>
                                    <small class="text-muted">${config.description || 'No description available'}</small>
                                </td>
                                <td>
                                    <button class="btn btn-sm btn-outline-primary" onclick="editConfig('${config.config_key}', ${config.config_value}, '${config.description || ''}')">
                                        <i class="fas fa-edit"></i> Edit
                                    </button>
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
    }

    function showLoadingSpinner(container) {
        container.innerHTML = `
            <div class="text-center py-8">
                <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">Loading...</span>
                </div>
                <p class="mt-2 text-muted">Loading configurations...</p>
            </div>
        `;
    }

    function hideLoadingSpinner(container, data, templateFunction) {
        container.innerHTML = templateFunction(data);
    }

    function loadConfigData() {
        const container = document.getElementById('config-container');
        if (!container) return;

        showLoadingSpinner(container);

        const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');

        fetch(API_BASE_URL + '/admin/config', {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + (token || '')
            }
        })
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            hideLoadingSpinner(container, data.configs, renderConfigTable);
        })
        .catch(error => {
            console.error('Error loading config data:', error);
            const fallbackData = [];
            hideLoadingSpinner(container, fallbackData, renderConfigTable);
        });
    }

    function editConfig(configKey, currentValue, description) {
        const modal = document.createElement('div');
        modal.innerHTML = `
            <div class="modal fade" id="editConfigModal" tabindex="-1">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">Edit Configuration</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <form id="editConfigForm">
                                <div class="mb-3">
                                    <label for="configKey" class="form-label">Configuration Key</label>
                                    <input type="text" class="form-control" id="configKey" value="${configKey}" readonly>
                                </div>
                                <div class="mb-3">
                                    <label for="configValue" class="form-label">Current Value</label>
                                    <input type="number" class="form-control" id="configValue" value="${currentValue}" step="0.01" required>
                                </div>
                                <div class="mb-3">
                                    <label for="configDescription" class="form-label">Description</label>
                                    <textarea class="form-control" id="configDescription" rows="2" readonly>${description}</textarea>
                                </div>
                            </form>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                            <button type="button" class="btn btn-primary" onclick="saveConfig()">Save Changes</button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(modal);
        const modalInstance = new bootstrap.Modal(document.getElementById('editConfigModal'));
        modalInstance.show();

        // Clean up modal after it's hidden
        document.getElementById('editConfigModal').addEventListener('hidden.bs.modal', function () {
            document.body.removeChild(modal);
        });
    }

    function saveConfig() {
        const configKey = document.getElementById('configKey').value;
        const configValue = document.getElementById('configValue').value;

        if (!configValue) {
            alert('Please enter a valid value');
            return;
        }

        const token = document.querySelector('meta[name="api-token"]')?.getAttribute('content');

        fetch(`${API_BASE_URL}/admin/config/${configKey}`, {
            method: 'PUT',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + (token || '')
            },
            body: JSON.stringify({
                value: parseFloat(configValue)
            })
        })
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            // Close modal
            const modal = bootstrap.Modal.getInstance(document.getElementById('editConfigModal'));
            modal.hide();

            // Reload data
            loadConfigData();

            // Show success message
            const alert = document.createElement('div');
            alert.className = 'alert alert-success alert-dismissible fade show';
            alert.innerHTML = `
                Configuration updated successfully!
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            `;
            document.querySelector('.card-body').insertBefore(alert, document.getElementById('config-container'));

            // Auto-dismiss after 3 seconds
            setTimeout(() => {
                if (alert.parentNode) {
                    alert.parentNode.removeChild(alert);
                }
            }, 3000);
        })
        .catch(error => {
            console.error('Error saving config:', error);
            alert('Failed to update configuration. Please try again.');
        });
    }

    // Load configuration data when page loads
    document.addEventListener('DOMContentLoaded', function() {
        loadConfigData();
    });
</script>
@endpush
