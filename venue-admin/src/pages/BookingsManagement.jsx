import React, { useState, useEffect, useContext, useMemo, useCallback } from 'react';
import { useParams } from 'react-router-dom';
import DataTable from '../components/DataTable';
import { Box, Button, Typography, Chip, Checkbox } from '@mui/joy';
import { AppContext } from '../context/AppContextProvider';
import axios from 'axios';
import Modalbox from '../components/Modalbox';
import toast from 'react-hot-toast';

function BookingsManagement() {
    const { venue_id } = useParams();
    const { backendUrl, token, venueOwner } = useContext(AppContext);
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [deleteModalOpen, setDeleteModalOpen] = useState(false);
    const [bookingToDelete, setBookingToDelete] = useState(null);
    const [deactivateModalOpen, setDeactivateModalOpen] = useState(false);
    const [bookingToDeactivate, setBookingToDeactivate] = useState(null);
    const [modalLoading, setModalLoading] = useState(false);
    const [payingId, setPayingId] = useState(null);
    const [paymentModalOpen, setPaymentModalOpen] = useState(false);
    const [bookingToPayment, setBookingToPayment] = useState(null);

    // Fetch bookings data for the venue
    const fetchVenueBookings = useCallback(async () => {
        setLoading(true);
        try {
            const response = await axios.get(
                `${backendUrl}/venue/bookings/${venueOwner.venue_id}`,
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status && response.data.data) {
                setBookings(response.data.data);
            }
            setLoading(false);
        } catch (error) {
            console.error('Error fetching venue bookings:', error);
            setLoading(false);
        }
    }, [backendUrl, venue_id, token, venueOwner]);

    useEffect(() => {
        fetchVenueBookings();
    }, [fetchVenueBookings]);

    // Define table columns
    const columns = useMemo(() => [
        {
            key: 'no',
            label: 'No.',
            width: 70,
            render: (_, __, index) => index + 1
        },
        {
            key: 'booking_id',
            label: 'Booking ID',
            width: 100
        },
        {
            key: 'user_first_name',
            label: 'User Name',
            width: 150,
            render: (value, row) => `${row.user_first_name} ${row.user_last_name}`
        },
        {
            key: 'user_email',
            label: 'Email',
            width: 180
        },
        {
            key: 'sport_name',
            label: 'Sport',
            width: 120
        },
        {
            key: 'booking_start',
            label: 'Start Time',
            width: 170,
            render: (value) => new Date(value).toLocaleString('en-IN', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            })
        },
        {
            key: 'booking_end',
            label: 'End Time',
            width: 170,
            render: (value) => new Date(value).toLocaleString('en-IN', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            })
        },
        {
            key: 'total_price',
            label: 'Total Price',
            width: 100,
            render: (value) => `₹${value}`
        },
        {
            key: 'payment',
            label: 'Payment',
            width: 110,
            render: (value, row) => (
                String(row.payment ?? value ?? '').toLowerCase() === 'paid' ? (
                    <Chip color="success" size="sm" variant="soft">Paid</Chip>
                ) : (
                    <Checkbox
                        label="Mark paid"
                        size="sm"
                        checked={false}
                        disabled={modalLoading}
                        onChange={() => handleMarkPaid(row)}
                    />
                )
            )
        },
        {
            key: 'game_status',
            label: 'Status',
            width: 80,
            render: (value) => (
                <Chip
                    color={value === 'active' ? 'success' : value === 'completed' ? 'neutral' : 'danger'}
                    size="sm"
                    variant="soft"
                >
                    {value}
                </Chip>
            )
        }
    ], []);

    const handleDeactivate = useCallback((booking) => {
        if (!booking?.game_id) return;
        setBookingToDeactivate(booking);
        setDeactivateModalOpen(true);
    }, []);

    const handleMarkPaid = useCallback((booking) => {
        if (!booking?.booking_id) return;
        if (String(booking.payment ?? '').toLowerCase() === 'paid') return;

        setBookingToPayment(booking);
        setPaymentModalOpen(true);
    }, []);

    const confirmMarkPaid = useCallback(async () => {
        if (!bookingToPayment?.booking_id) return;

        setModalLoading(true);
        try {
            const response = await axios.patch(
                `${backendUrl}/venue/bookings/payment-status/${bookingToPayment.booking_id}`,
                {},
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status) {
                setBookings((prev) =>
                    prev.map((b) =>
                        b.booking_id === bookingToPayment.booking_id
                            ? { ...b, payment: 'paid' }
                            : b
                    )
                );
                toast.success(`Booking #${bookingToPayment.booking_id} marked as paid`);
                setPaymentModalOpen(false);
                setBookingToPayment(null);
            } else {
                toast.error(response.data.message || 'Failed to update payment status');
            }
        } catch (error) {
            console.error('Error updating payment status:', error);
            toast.error(error.response?.data?.message || 'Failed to update payment status');
        } finally {
            setModalLoading(false);
        }
    }, [backendUrl, token, bookingToPayment]);

    const confirmDeactivate = useCallback(async () => {
        if (!bookingToDeactivate?.booking_id) return;

        setModalLoading(true);
        try {
            const response = await axios.patch(
                `${backendUrl}/venue/bookings/deactivate/${bookingToDeactivate.game_id}`,
                {},
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status) {
                // Update booking status to cancelled/inactive
                setBookings((prev) =>
                    prev.map((b) =>
                        b.booking_id === bookingToDeactivate.booking_id
                            ? { ...b, game_status: 'cancelled' }
                            : b
                    )
                );
                setDeactivateModalOpen(false);
                setBookingToDeactivate(null);
            } else {
                console.error('Failed to deactivate booking:', response.data.message);
            }
        } catch (error) {
            console.error('Error deactivating booking:', error);
        } finally {
            setModalLoading(false);
        }
    }, [backendUrl, token, bookingToDeactivate]);

    const handleDelete = useCallback((booking) => {
        if (!booking?.booking_id) return;
        setBookingToDelete(booking);
        setDeleteModalOpen(true);
    }, []);

    const confirmDelete = useCallback(async () => {
        if (!bookingToDelete?.booking_id) return;

        try {
            setLoading(true);
            const response = await axios.delete(
                `${backendUrl}/venue/bookings/${bookingToDelete.booking_id}`,
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );

            if (response.data.status) {
                setBookings((prev) => prev.filter((b) => b.booking_id !== bookingToDelete.booking_id));
                toast.success('Booking deleted successfully');
            } else {
                console.error('Failed to delete booking', response.data);
            }
        } catch (error) {
            console.error('Error deleting booking:', error);
        } finally {
            setLoading(false);
            setDeleteModalOpen(false);
            setBookingToDelete(null);
        }
    }, [backendUrl, token, bookingToDelete]);

    // Define table actions
    const actions = useMemo(() => [
        {
            label: 'Deactivate',
            variant: 'soft',
            color: 'primary',
            onClick: (row) => handleDeactivate(row)
        },
        {
            label: 'Delete',
            variant: 'soft',
            color: 'danger',
            onClick: (row) => handleDelete(row)
        }
    ], [handleDeactivate, handleDelete]);

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
                        Bookings Management
                    </Typography>
                    <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                        Manage all bookings for your venue
                    </Typography>
                </Box>
                <Button
                    variant="outlined"
                    size="sm"
                    loading={loading}
                    onClick={fetchVenueBookings}
                    sx={{
                        minWidth: 'auto',
                        px: 2
                    }}
                >
                    {loading ? 'Refreshing...' : 'Refresh'}
                </Button>
            </Box>

            {/* DataTable */}
            <DataTable
                columns={columns}
                rows={bookings}
                actions={actions}
                loading={loading}
                searchable={true}
                searchPlaceholder="Search bookings..."
                pageSize={7}
                firstColumnWidth={50}
                lastColumnWidth={190}
            />

            <Modalbox
                open={deleteModalOpen}
                setOpen={setDeleteModalOpen}
                title="Delete booking"
                onConfirm={confirmDelete}
                onCancel={() => setBookingToDelete(null)}
                confirmText="Delete"
                cancelText="Cancel"
                color="danger"
                width={420}
            >
                <Typography level="body-md" sx={{ mb: 1 }}>
                    Are you sure you want to delete booking ID {bookingToDelete?.booking_id}?
                </Typography>
                <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                    This action cannot be undone.
                </Typography>
            </Modalbox>

            <Modalbox
                open={deactivateModalOpen}
                setOpen={setDeactivateModalOpen}
                title="Deactivate Booking"
                onConfirm={confirmDeactivate}
                onCancel={() => setBookingToDeactivate(null)}
                confirmText="Deactivate"
                cancelText="Cancel"
                color="warning"
                width={420}
            >
                <Typography level="body-md" sx={{ mb: 2 }}>
                    Are you sure you want to deactivate game <strong>#{bookingToDeactivate?.game_id}</strong> (booking ID #{bookingToDeactivate?.booking_id})?
                </Typography>
                <Typography level="body-sm" sx={{ color: 'neutral.500', mb: 1 }}>
                    User: <strong>{bookingToDeactivate?.user_first_name} {bookingToDeactivate?.user_last_name}</strong>
                </Typography>
                <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                    Sport: <strong>{bookingToDeactivate?.sport_name}</strong>
                </Typography>
            </Modalbox>
            <Modalbox
                open={paymentModalOpen}
                setOpen={setPaymentModalOpen}
                title="Confirm Payment"
                onConfirm={confirmMarkPaid}
                onCancel={() => setBookingToPayment(null)}
                confirmText="Mark Paid"
                cancelText="Cancel"
                color="success"
                width={420}
            >
                <Typography level="body-md" sx={{ mb: 2 }}>
                    Mark booking <strong>#{bookingToPayment?.booking_id}</strong> as paid?
                </Typography>
                <Typography level="body-sm" sx={{ color: 'neutral.500', mb: 1 }}>
                    User: <strong>{bookingToPayment?.user_first_name} {bookingToPayment?.user_last_name}</strong>
                </Typography>
                <Typography level="body-sm" sx={{ color: 'neutral.500', mb: 1 }}>
                    Amount: <strong>₹{bookingToPayment?.total_price}</strong>
                </Typography>
                <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                    Sport: <strong>{bookingToPayment?.sport_name}</strong>
                </Typography>
            </Modalbox>        </Box>
    );
}

export default BookingsManagement;