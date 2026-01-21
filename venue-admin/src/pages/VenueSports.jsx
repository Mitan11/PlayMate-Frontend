import React, { useState, useEffect, useContext, useMemo, useCallback } from 'react';
import { useParams } from 'react-router-dom';
import DataTable from '../components/DataTable';
import { Box, Button, Typography, Select, Option, FormControl, FormLabel, FormHelperText } from '@mui/joy';
import { AppContext } from '../context/AppContextProvider';
import axios from 'axios';
import Modalbox from '../components/Modalbox';

function VenueSports() {
    const { venue_id } = useParams();
    const { backendUrl, token, venueOwner } = useContext(AppContext);
    const [sports, setSports] = useState([]);
    const [loading, setLoading] = useState(true);
    const [modalOpen, setModalOpen] = useState(false);
    const [allSports, setAllSports] = useState([]);
    const [selectedSportId, setSelectedSportId] = useState('');
    const [modalLoading, setModalLoading] = useState(false);
    const [formError, setFormError] = useState('');
    const [deleteModalOpen, setDeleteModalOpen] = useState(false);
    const [sportToDelete, setSportToDelete] = useState(null);
    const [editModalOpen, setEditModalOpen] = useState(false);
    const [sportToEdit, setSportToEdit] = useState(null);

    // Fetch sports data for the venue
    const fetchVenueSports = useCallback(async () => {
        setLoading(true);
        try {
            const response = await axios.get(
                `${backendUrl}/venue/sports/${venueOwner.venue_id}`,
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status && response.data.data) {
                setSports(response.data.data);
            }
            setLoading(false);
        } catch (error) {
            console.error('Error fetching venue sports:', error);
            setLoading(false);
        }
    }, [backendUrl, venue_id, token]);

    useEffect(() => {
        fetchVenueSports();
    }, [fetchVenueSports]);

    // Define table columns
    const columns = useMemo(() => [
        {
            key: 'venue_sport_id',
            label: 'Venue Sport ID',
            width: 140
        },
        {
            key: 'sport_id',
            label: 'Sport ID',
            width: 100
        },
        {
            key: 'sport_name',
            label: 'Sport Name',
            width: 200
        },
        {
            key: 'created_at',
            label: 'Created At',
            width: 200,
            render: (value) => new Date(value).toLocaleString('en-IN', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            })
        }
    ], []);

    const fetchAllSports = useCallback(async () => {
        try {
            const response = await axios.get(
                `${backendUrl}/venue/allSports`,
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );
            if (response.data.status && response.data.data) {
                setAllSports(response.data.data);
            }
        } catch (error) {
            console.error('Error fetching all sports:', error);
        }
    }, [backendUrl, token]);

    const handleEdit = useCallback((sport) => {
        setSportToEdit(sport);
        setSelectedSportId(sport.sport_id);
        setFormError('');
        fetchAllSports();
        setEditModalOpen(true);
    }, [fetchAllSports]);

    const confirmEdit = useCallback(async () => {
        setFormError('');
        
        if (!selectedSportId) {
            setFormError('Please select a sport');
            setTimeout(() => setEditModalOpen(true), 0);
            return;
        }

        setModalLoading(true);
        try {
            const response = await axios.put(
                `${backendUrl}/venue/sports/${sportToEdit.venue_sport_id}`,
                {
                    sport_id: selectedSportId
                },
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status) {
                fetchVenueSports();
                setEditModalOpen(false);
                setSportToEdit(null);
                setSelectedSportId('');
                setFormError('');
            } else {
                setFormError(response.data.message || 'Failed to update sport');
                setTimeout(() => setEditModalOpen(true), 0);
            }
        } catch (error) {
            console.error('Error updating sport:', error);
            setFormError(error.response?.data?.message || 'Failed to update sport');
            setTimeout(() => setEditModalOpen(true), 0);
        } finally {
            setModalLoading(false);
        }
    }, [selectedSportId, backendUrl, token, sportToEdit, fetchVenueSports]);

    const handleDelete = useCallback((sport) => {
        setSportToDelete(sport);
        setDeleteModalOpen(true);
    }, []);

    const confirmDelete = useCallback(async () => {
        if (!sportToDelete) return;

        setModalLoading(true);
        try {
            const response = await axios.delete(
                `${backendUrl}/venue/sports/${sportToDelete.venue_sport_id}`,
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status) {
                setSports(prevSports => prevSports.filter(s => s.venue_sport_id !== sportToDelete.venue_sport_id));
                setDeleteModalOpen(false);
                setSportToDelete(null);
                setFormError('');
            } else {
                setFormError(response.data.message || 'Failed to delete sport');
                setTimeout(() => setDeleteModalOpen(true), 0);
            }
        } catch (error) {
            console.error('Error deleting sport:', error);
            setFormError(error.response?.data?.message || 'Failed to delete sport');
            setTimeout(() => setDeleteModalOpen(true), 0);
        } finally {
            setModalLoading(false);
        }
    }, [sportToDelete, backendUrl, token]);

    const handleAddSport = useCallback(() => {
        setSelectedSportId('');
        setFormError('');
        fetchAllSports();
        setModalOpen(true);
    }, [fetchAllSports]);

    const handleConfirmAddSport = useCallback(async () => {
        setFormError('');

        if (!selectedSportId) {
            setFormError('Please select a sport');
            // Prevent modal from closing by keeping it open
            setTimeout(() => setModalOpen(true), 0);
            return;
        }

        setModalLoading(true);
        try {
            const response = await axios.post(
                `${backendUrl}/venue/sports`,
                {
                    venue_id: venueOwner.venue_id,
                    sport_id: selectedSportId
                },
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status) {
                fetchVenueSports();
                setModalOpen(false);
                setSelectedSportId('');
                setFormError('');
            } else {
                setFormError(response.data.message || 'Failed to add sport');
                // Keep modal open on error
                setTimeout(() => setModalOpen(true), 0);
            }
        } catch (error) {
            console.error('Error adding sport:', error);
            setFormError(error.response?.data?.message || 'Failed to add sport');
            // Keep modal open on error
            setTimeout(() => setModalOpen(true), 0);
        } finally {
            setModalLoading(false);
        }
    }, [selectedSportId, backendUrl, token, venueOwner, fetchVenueSports]);

    // Define table actions
    const actions = useMemo(() => [
        {
            label: 'Edit',
            variant: 'soft',
            color: 'primary',
            onClick: (row) => handleEdit(row)
        },
        {
            label: 'Delete',
            variant: 'soft',
            color: 'danger',
            onClick: (row) => handleDelete(row)
        }
    ], [handleEdit, handleDelete, confirmDelete, confirmEdit]);

    return (
        <Box sx={{ p: 3 }}>
            {/* Header */}
            <Box sx={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                mb: 3
            }}>
                <Box>
                    <Typography level="h2" sx={{ mb: 0.5 }}>
                        Venue Sports Management
                    </Typography>
                    <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                        Manage the sports available in your Venue
                    </Typography>
                </Box>
                <Box sx={{ display: 'flex', gap: 2 }}>
                    <Button
                        color="primary"
                        onClick={handleAddSport}
                    >
                        + Add Sport
                    </Button>
                    <Button
                        variant="outlined"
                        size="sm"
                        loading={loading}
                        onClick={fetchVenueSports}
                        sx={{
                            minWidth: 'auto',
                            px: 2
                        }}
                    >
                        {loading ? 'Refreshing...' : 'Refresh'}
                    </Button>
                </Box>
            </Box>

            {/* DataTable */}
            <DataTable
                columns={columns}
                rows={sports}
                actions={actions}
                loading={loading}
                searchable={true}
                searchPlaceholder="Search sports..."
                pageSize={7}
                firstColumnWidth={140}
                lastColumnWidth={160}
            />

            {/* Add Sport Modal */}
            <Modalbox
                open={modalOpen}
                setOpen={setModalOpen}
                title="Add Sport to Venue"
                onConfirm={handleConfirmAddSport}
                confirmText="Add Sport"
                cancelText="Cancel"
                width={500}
            >
                <FormControl error={!!formError} sx={{ mb: 2 }}>
                    <FormLabel>Select Sport</FormLabel>
                    <Select
                        placeholder="Choose a sport"
                        value={selectedSportId}
                        onChange={(e, newValue) => {
                            setSelectedSportId(newValue);
                            setFormError('');
                        }}
                        disabled={modalLoading}
                        color={formError ? 'danger' : 'neutral'}
                    >
                        {allSports.map((sport) => (
                            <Option key={sport.sport_id} value={sport.sport_id}>
                                {sport.sport_name}
                            </Option>
                        ))}
                    </Select>
                    {formError && (
                        <FormHelperText sx={{ color: 'danger.500' }}>
                            {formError}
                        </FormHelperText>
                    )}
                </FormControl>
            </Modalbox>

            {/* Delete Confirmation Modal */}
            <Modalbox
                open={deleteModalOpen}
                setOpen={setDeleteModalOpen}
                title="Confirm Delete"
                onConfirm={confirmDelete}
                confirmText="Delete"
                cancelText="Cancel"
                width={400}
                color="danger"
            >
                <Typography level="body-md">
                    Are you sure you want to delete <strong>{sportToDelete?.sport_name}</strong>?
                    This action cannot be undone.
                </Typography>
            </Modalbox>

            {/* Edit Sport Modal */}
            <Modalbox
                open={editModalOpen}
                setOpen={setEditModalOpen}
                title="Edit Venue Sport"
                onConfirm={confirmEdit}
                confirmText="Update Sport"
                cancelText="Cancel"
                width={500}
            >
                <FormControl error={!!formError} sx={{ mb: 2 }}>
                    <FormLabel>Select Sport</FormLabel>
                    <Select
                        placeholder="Choose a sport"
                        value={selectedSportId}
                        onChange={(e, newValue) => {
                            setSelectedSportId(newValue);
                            setFormError('');
                        }}
                        disabled={modalLoading}
                        color={formError ? 'danger' : 'neutral'}
                    >
                        {allSports.map((sport) => (
                            <Option key={sport.sport_id} value={sport.sport_id}>
                                {sport.sport_name}
                            </Option>
                        ))}
                    </Select>
                    {formError && (
                        <FormHelperText sx={{ color: 'danger.500' }}>
                            {formError}
                        </FormHelperText>
                    )}
                </FormControl>
                <Typography level="body-sm" sx={{ color: 'neutral.500', mt: 1 }}>
                    Current sport: <strong>{sportToEdit?.sport_name}</strong>
                </Typography>
            </Modalbox>
        </Box>
    );
}

export default VenueSports;