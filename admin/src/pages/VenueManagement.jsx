import React, { useCallback, useEffect, useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import toast from 'react-hot-toast'
import Box from '@mui/joy/Box'
import Typography from '@mui/joy/Typography'
import Button from '@mui/joy/Button'
import DataTable from '../components/DataTable'
import Modal from '../components/Modalbox'
import { useDispatch, useSelector } from 'react-redux'
import {
    selectVenues,
    selectVenuesError,
    selectVenuesStatus,
} from '../features/venues/venuesSelectors'
import { fetchVenues, removeVenue } from '../features/venues/venuesThunks'
import { clearVenuesError as clearVenuesErrorAction } from '../features/venues/venuesSlice'

function VenueManagement() {
    const dispatch = useDispatch()
    const venues = useSelector(selectVenues)
    const status = useSelector(selectVenuesStatus)
    const error = useSelector(selectVenuesError)
    const loading = status === 'loading'
    const [openModal, setOpenModal] = useState(false)
    const [selectedVenue, setSelectedVenue] = useState({ id: null, name: '' })

    const containerVariants = {
        hidden: { opacity: 0, y: 10 },
        visible: {
            opacity: 1,
            y: 0,
            transition: { duration: 0.5, staggerChildren: 0.1 },
        },
    }

    useEffect(() => {
        dispatch(fetchVenues())
    }, [dispatch])

    useEffect(() => {
        if (error) {
            toast.error(error)
            dispatch(clearVenuesErrorAction())
        }
    }, [error, dispatch])

    const columns = useMemo(
        () => [
            { key: 'no', label: 'NO', width: 50 },
            { key: 'venue_id', label: 'ID', width: 70 },
            { 
                key: 'profile_image', 
                label: 'Avatar', 
                width: 80,
                render: (value) => (
                    <img 
                        src={value} 
                        alt="Profile" 
                        style={{ width: 40, height: 40, borderRadius: '50%', objectFit: 'cover' }}
                        onError={(e) => { e.target.src = 'https://via.placeholder.com/40x40?text=V' }}
                    />
                )
            },
            { key: 'first_name', label: 'First Name', width: 120 },
            { key: 'last_name', label: 'Last Name', width: 120 },
            { key: 'email', label: 'Email', width: 200 },
            { key: 'phone', label: 'Phone', width: 130 },
            { key: 'venue_name', label: 'Venue Name', width: 180 },
            { key: 'address', label: 'Address', width: 150 },
            { key: 'sports', label: 'Sports', width: 250 },
            { key: 'created_at', label: 'Joined', width: 140 },
        ],
        []
    )

    const rows = useMemo(
        () =>
            venues.map((venue, index) => {
                const sportsText = venue.sports?.map(sport => 
                    `${sport.sport_name}`).join(', ') || 'No sports available'

                return {
                    no: index + 1,
                    venue_id: venue.venue_id,
                    profile_image: venue.profile_image || 'https://via.placeholder.com/40x40?text=V',
                    first_name: venue.first_name || '—',
                    last_name: venue.last_name || '—',
                    email: venue.email ?? '—',
                    phone: venue.phone ?? '—',
                    venue_name: venue.venue_name || '—',
                    address: venue.address || '—',
                    sports: sportsText,
                    created_at: venue.created_at
                        ? new Date(venue.created_at).toLocaleString()
                        : '—',
                }
            }),
        [venues]
    )

    const handleDeleteClick = useCallback((row) => {
        const id = row.venue_id
        if (!id) {
            toast.error('Unable to identify this venue')
            return
        }

        setSelectedVenue({ id, name: row.venue_name || `${row.first_name} ${row.last_name}`.trim() })
        setOpenModal(true)
    }, [])

    const deleteVenue = useCallback(async () => {
        if (!selectedVenue.id) return

        try {
            await dispatch(removeVenue(selectedVenue.id)).unwrap()
            toast.success('Venue deleted successfully')
            dispatch(fetchVenues())
        } catch (err) {
            console.error('Failed to delete venue:', err)
        } finally {
            setOpenModal(false)
            setSelectedVenue({ id: null, name: '' })
        }
    }, [dispatch, selectedVenue.id])

    const handleCancelDelete = useCallback(() => {
        setOpenModal(false)
        setSelectedVenue({ id: null, name: '' })
    }, [])

    const actions = useMemo(
        () => [
            {
                label: 'Delete',
                color: 'danger',
                variant: 'soft',
                onClick: (row) => handleDeleteClick(row),
            },
        ],
        [handleDeleteClick]
    )

    return (
        <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            style={{ width: '100%', maxWidth: '100%', overflowX: 'hidden' }}
        >
            <Box sx={{ p: { xs: 1.5, sm: 2, md: 3 }, maxWidth: '100%', overflowX: 'hidden' }}>
                <Modal
                    open={openModal}
                    setOpen={setOpenModal}
                    title="Confirm Delete"
                    onConfirm={deleteVenue}
                    onCancel={handleCancelDelete}
                    confirmText="Delete"
                    cancelText="Cancel"
                    width={400}
                    minWidth={250}
                    color="danger"
                >
                    <Typography id="modal-desc" textColor="text.tertiary" sx={{ mb: 3 }}>
                        Are you sure you want to delete {selectedVenue.name || 'this venue'}?
                    </Typography>
                </Modal>

                <Box sx={{ mb: 3 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 1 }}>
                        <Box>
                            <Typography level="h2" sx={{ fontSize: { xs: '1.5rem', sm: '1.875rem', md: '2.25rem' } }}>
                                Venue Management
                            </Typography>
                            <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                                View and manage all venues in the platform
                            </Typography>
                        </Box>
                        <Button
                            variant="outlined"
                            color="neutral"
                            loading={loading}
                            onClick={() => dispatch(fetchVenues())}
                        >
                            Refresh
                        </Button>
                    </Box>
                </Box>

                <DataTable
                    columns={columns}
                    rows={rows}
                    actions={actions}
                    loading={loading}
                    searchPlaceholder="Search venues..."
                />
            </Box>
        </motion.div>
    )
}

export default VenueManagement