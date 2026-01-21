import React, { useState, useEffect, useContext, useMemo, useCallback } from 'react';
import { useParams } from 'react-router-dom';
import DataTable from '../components/DataTable';
import { Box, Button, Typography, Chip } from '@mui/joy';
import { AppContext } from '../context/AppContextProvider';
import axios from 'axios';

function BookingsManagement() {
    const { venue_id } = useParams();
    const { backendUrl, token, venueOwner } = useContext(AppContext);
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);

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
            width: 120,
            render: (value) => `₹${value}`
        },
        {
            key: 'game_status',
            label: 'Status',
            width: 120,
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

    const handleView = useCallback((booking) => {
        console.log('View booking:', booking);
        // TODO: Implement view details
    }, []);

    const handleCancel = useCallback((booking) => {
        console.log('Cancel booking:', booking);
        // TODO: Implement cancel functionality
    }, []);

    // Define table actions
    const actions = useMemo(() => [
        {
            label: 'View',
            variant: 'soft',
            color: 'primary',
            onClick: (row) => handleView(row)
        },
        {
            label: 'Cancel',
            variant: 'soft',
            color: 'danger',
            onClick: (row) => handleCancel(row)
        }
    ], [handleView, handleCancel]);

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
                firstColumnWidth={100}
                lastColumnWidth={160}
            />
        </Box>
    );
}

export default BookingsManagement;