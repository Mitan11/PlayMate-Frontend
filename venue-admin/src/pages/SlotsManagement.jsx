import React, { useState, useEffect, useContext, useMemo, useCallback } from 'react';
import { useParams } from 'react-router-dom';
import DataTable from '../components/DataTable';
import { Box, Button, Typography, Chip, Input, FormControl, FormLabel, Select, Option } from '@mui/joy';
import { AppContext } from '../context/AppContextProvider';
import axios from 'axios';
import Modalbox from '../components/Modalbox';
import toast from 'react-hot-toast';

function SlotsManagement() {
    const { venue_id } = useParams();
    const { backendUrl, token, venueOwner, getVenueSpots } = useContext(AppContext);
    const [slots, setSlots] = useState([]);
    const [loading, setLoading] = useState(true);
    const [deleteModalOpen, setDeleteModalOpen] = useState(false);
    const [slotToDelete, setSlotToDelete] = useState(null);
    const [modalLoading, setModalLoading] = useState(false);
    const [createModalOpen, setCreateModalOpen] = useState(false);
    const [editModalOpen, setEditModalOpen] = useState(false);
    const [editingSlot, setEditingSlot] = useState(null);
    const [form, setForm] = useState({
        sport_id: '',
        start_time: '',
        end_time: '',
        price_per_slot: ''
    });
    const [submitting, setSubmitting] = useState(false);
    const [sports, setSports] = useState([]);

    // Fetch sports data for the venue
    const fetchVenueSports = useCallback((setSports, setLoading) => { getVenueSpots(setSports, setLoading) }, [backendUrl, venue_id, token]);

    useEffect(() => {
        fetchVenueSports(setSports, setLoading);
    }, [fetchVenueSports]);

    // Fetch venue slots data
    const fetchVenueSlots = useCallback(async () => {
        setLoading(true);
        try {
            const response = await axios.get(
                `${backendUrl}/venue/allVenueSlots/${venueOwner.venue_id}`,
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status && response.data.data) {
                setSlots(response.data.data);
            }
            console.log("Slots Data:", response);

            setLoading(false);
        } catch (error) {
            console.error('Error fetching venue slots:', error);
            toast.error('Failed to fetch slots');
            setLoading(false);
        }
    }, [backendUrl, token, venueOwner, venue_id]);

    useEffect(() => {
        fetchVenueSlots();
    }, [fetchVenueSlots]);

    const resetForm = useCallback(() => {
        setForm({ sport_id: '', start_time: '', end_time: '', price_per_slot: '' });
    }, []);

    const handleOpenCreate = useCallback(() => {
        resetForm();
        setCreateModalOpen(true);
    }, [resetForm]);

    const handleOpenEdit = useCallback((slot) => {
        if (!slot) return;
        setEditingSlot(slot);
        setForm({
            venue_sport_id: slot.venue_sport_id ?? '',
            start_time: slot.start_time ?? '',
            end_time: slot.end_time ?? '',
            price_per_slot: String(slot.price_per_slot ?? '')
        });
        setEditModalOpen(true);
    }, []);

    const validateForm = useCallback(() => {
        if (!form.venue_sport_id || !form.start_time || !form.end_time || !form.price_per_slot) {
            toast.error('Please fill all fields');
            return false;
        }
        // Basic time order check HH:MM:SS
        if (form.start_time >= form.end_time) {
            toast.error('End time must be after start time');
            return false;
        }
        return true;
    }, [form]);

    const handleCreateSlot = useCallback(async () => {
        if (!validateForm()) return;
        setSubmitting(true);
        try {
            const payload = {
                venue_sport_id: Number(form.venue_sport_id),
                start_time: form.start_time,
                end_time: form.end_time,
                price_per_slot: Number(form.price_per_slot)
            };

            const response = await axios.post(
                `${backendUrl}/venue/slots`,
                payload,
                { headers: { Authorization: `Bearer ${token}` } }
            );

            if (response.data?.status) {
                toast.success('Slot created');
                setCreateModalOpen(false);
                resetForm();
                await fetchVenueSlots();
            } else {
                toast.error(response.data?.message || 'Failed to create slot');
            }
        } catch (error) {
            console.error('Error creating slot:', error);
            toast.error(error.response?.data?.message || 'Failed to create slot');
        } finally {
            setSubmitting(false);
        }
    }, [backendUrl, token, venueOwner, form, validateForm, resetForm, fetchVenueSlots]);

    const handleUpdateSlot = useCallback(async () => {
        if (!editingSlot?.slot_id) return;
        if (!validateForm()) return;
        setSubmitting(true);
        try {
            const payload = {
                venue_sport_id: Number(form.venue_sport_id),
                start_time: form.start_time,
                end_time: form.end_time,
                price_per_slot: Number(form.price_per_slot)
            };

            const response = await axios.patch(
                `${backendUrl}/venue/slots/${editingSlot.slot_id}`,
                payload,
                { headers: { Authorization: `Bearer ${token}` } }
            );

            if (response.data?.status) {
                toast.success('Slot updated');
                setEditModalOpen(false);
                setEditingSlot(null);
                // Update local state without refetch
                setSlots((prev) => prev.map((s) => s.slot_id === editingSlot.slot_id ? { ...s, ...payload } : s));
            } else {
                toast.error(response.data?.message || 'Failed to update slot');
            }
        } catch (error) {
            console.error('Error updating slot:', error);
            toast.error(error.response?.data?.message || 'Failed to update slot');
        } finally {
            setSubmitting(false);
        }
    }, [backendUrl, token, editingSlot, form, validateForm]);

    // Define table columns
    const columns = useMemo(() => [
        {
            key: 'no',
            label: 'No.',
            width: 70,
            render: (_, __, index) => index + 1
        },
        {
            key: 'slot_id',
            label: 'Slot ID',
            width: 100
        },
        {
            key: 'sport_name',
            label: 'Sport',
            width: 120
        },
        {
            key: 'start_time',
            label: 'Start Time',
            width: 140,
            render: (value) => {
                // Handle HH:MM:SS format
                const today = new Date().toISOString().split('T')[0];
                return new Date(`${today}T${value}`).toLocaleString('en-IN', {
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit'
                });
            }
        },
        {
            key: 'end_time',
            label: 'End Time',
            width: 140,
            render: (value) => {
                // Handle HH:MM:SS format
                const today = new Date().toISOString().split('T')[0];
                return new Date(`${today}T${value}`).toLocaleString('en-IN', {
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit'
                });
            }
        },
        {
            key: 'price_per_slot',
            label: 'Price',
            width: 100,
            render: (value) => `₹${value}`
        },
        {
            key: 'slot_created_at',
            label: 'Created',
            width: 170,
            render: (value) => new Date(value).toLocaleString('en-IN', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            })
        }
    ], []);

    const handleDelete = useCallback((slot) => {
        if (!slot?.slot_id) return;
        setSlotToDelete(slot);
        setDeleteModalOpen(true);
    }, []);

    const confirmDelete = useCallback(async () => {
        if (!slotToDelete?.slot_id) return;

        try {
            setModalLoading(true);
            const response = await axios.delete(
                `${backendUrl}/venue/slots/${slotToDelete.slot_id}`,
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status) {
                setSlots((prev) => prev.filter((s) => s.slot_id !== slotToDelete.slot_id));
                toast.success('Slot deleted successfully');
            } else {
                toast.error(response.data.message || 'Failed to delete slot');
            }
        } catch (error) {
            console.error('Error deleting slot:', error);
            toast.error(error.response?.data?.message || 'Failed to delete slot');
        } finally {
            setModalLoading(false);
            setDeleteModalOpen(false);
            setSlotToDelete(null);
        }
    }, [backendUrl, token, slotToDelete]);

    // Define table actions
    const actions = useMemo(() => [
        {
            label: 'Edit',
            variant: 'soft',
            color: 'primary',
            onClick: (row) => handleOpenEdit(row)
        },
        {
            label: 'Delete',
            variant: 'soft',
            color: 'danger',
            onClick: (row) => handleDelete(row)
        }
    ], [handleOpenEdit, handleDelete]);

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
                        Slots Management
                    </Typography>
                    <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                        Manage all slots for your venue
                    </Typography>
                </Box>
                <Box sx={{ display: 'flex', gap: 1 }}>
                    <Button
                        variant="solid"
                        size="sm"
                        color="primary"
                        onClick={handleOpenCreate}
                        sx={{ minWidth: 'auto', px: 2 }}
                    >
                        Add Slot
                    </Button>
                    <Button
                        variant="outlined"
                        size="sm"
                        loading={loading}
                        onClick={fetchVenueSlots}
                        sx={{ minWidth: 'auto', px: 2 }}
                    >
                        {loading ? 'Refreshing...' : 'Refresh'}
                    </Button>
                </Box>
            </Box>

            {/* DataTable */}
            <DataTable
                columns={columns}
                rows={slots}
                actions={actions}
                loading={loading}
                searchable={true}
                searchPlaceholder="Search slots..."
                pageSize={7}
                firstColumnWidth={50}
                lastColumnWidth={150}
            />

            <Modalbox
                open={deleteModalOpen}
                setOpen={setDeleteModalOpen}
                title="Delete slot"
                onConfirm={confirmDelete}
                onCancel={() => setSlotToDelete(null)}
                confirmText="Delete"
                cancelText="Cancel"
                color="danger"
                width={420}
            >
                <Typography level="body-md" sx={{ mb: 1 }}>
                    Are you sure you want to delete slot ID {slotToDelete?.slot_id}?
                </Typography>
                <Typography level="body-sm" sx={{ color: 'neutral.500', mb: 2 }}>
                    Sport: <strong>{slotToDelete?.sport_name}</strong>
                </Typography>
                <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                    This action cannot be undone.
                </Typography>
            </Modalbox>

            {/* Create Slot Modal */}
            <Modalbox
                open={createModalOpen}
                setOpen={setCreateModalOpen}
                title="Add Slot"
                onConfirm={handleCreateSlot}
                onCancel={resetForm}
                confirmText={submitting ? 'Saving...' : 'Save'}
                cancelText="Cancel"
                color="success"
                width={520}
            >
                <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2, mb: 2 }}>
                    <FormControl>
                        <FormLabel>Sport</FormLabel>
                        <Select
                            placeholder="Choose a sport"
                            value={form.venue_sport_id}
                            onChange={(e, newValue) => setForm((f) => ({ ...f, venue_sport_id: newValue }))}
                        >
                            {sports.map((sport) => (
                                <Option key={sport.venue_sport_id} value={sport.venue_sport_id}>
                                    {sport.sport_name}
                                </Option>
                            ))}
                        </Select>
                    </FormControl>
                    <FormControl>
                        <FormLabel>Price per Slot (₹)</FormLabel>
                        <Input
                            type="number"
                            value={form.price_per_slot}
                            onChange={(e) => setForm((f) => ({ ...f, price_per_slot: e.target.value }))}
                            placeholder="e.g., 500"
                            min={0}
                        />
                    </FormControl>
                    <FormControl>
                        <FormLabel>Start Time</FormLabel>
                        <Input
                            type="time"
                            value={form.start_time}
                            onChange={(e) => setForm((f) => ({ ...f, start_time: e.target.value }))}
                        />
                    </FormControl>
                    <FormControl>
                        <FormLabel>End Time</FormLabel>
                        <Input
                            type="time"
                            value={form.end_time}
                            onChange={(e) => setForm((f) => ({ ...f, end_time: e.target.value }))}
                        />
                    </FormControl>
                </Box>
                <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                    Tip: Ensure the time range doesn’t overlap existing slots.
                </Typography>
            </Modalbox>

            {/* Edit Slot Modal */}
            <Modalbox
                open={editModalOpen}
                setOpen={setEditModalOpen}
                title={`Edit Slot ${editingSlot?.slot_id ?? ''}`}
                onConfirm={handleUpdateSlot}
                onCancel={() => setEditingSlot(null)}
                confirmText={submitting ? 'Updating...' : 'Update'}
                cancelText="Cancel"
                color="primary"
                width={520}
            >
                <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2, mb: 2 }}>
                    <FormControl>
                        <FormLabel>Sport</FormLabel>
                        <Select
                            placeholder="Choose a sport"
                            value={form.venue_sport_id}
                            onChange={(e, newValue) => setForm((f) => ({ ...f, venue_sport_id: newValue }))}
                        >
                            {sports.map((sport) => (
                                <Option key={sport.venue_sport_id} value={sport.venue_sport_id}>
                                    {sport.sport_name}
                                </Option>
                            ))}
                        </Select>
                    </FormControl>
                    <FormControl>
                        <FormLabel>Price per Slot (₹)</FormLabel>
                        <Input
                            type="number"
                            value={form.price_per_slot}
                            onChange={(e) => setForm((f) => ({ ...f, price_per_slot: e.target.value }))}
                            min={0}
                        />
                    </FormControl>
                    <FormControl>
                        <FormLabel>Start Time</FormLabel>
                        <Input
                            type="time"
                            value={form.start_time}
                            onChange={(e) => setForm((f) => ({ ...f, start_time: e.target.value }))}
                        />
                    </FormControl>
                    <FormControl>
                        <FormLabel>End Time</FormLabel>
                        <Input
                            type="time"
                            value={form.end_time}
                            onChange={(e) => setForm((f) => ({ ...f, end_time: e.target.value }))}
                        />
                    </FormControl>
                </Box>
                <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                    Editing slot will affect future bookings only.
                </Typography>
            </Modalbox>
        </Box>
    );
}

export default SlotsManagement;