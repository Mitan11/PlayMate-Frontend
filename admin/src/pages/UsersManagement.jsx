import React, { useCallback, useContext, useEffect, useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import axios from 'axios'
import toast from 'react-hot-toast'
import Box from '@mui/joy/Box'
import Typography from '@mui/joy/Typography'
import Button from '@mui/joy/Button'
import DataTable from '../components/DataTable'
import Modal from '../components/Modalbox'
import { AppContext } from '../context/AppContextProvider'

function UsersManagement() {
    const { backendUrl, aToken } = useContext(AppContext)

    const [users, setUsers] = useState([])
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState(null)
    const [openModal, setOpenModal] = useState(false)
    const [selectedUser, setSelectedUser] = useState({ id: null, name: '' })

    const containerVariants = {
        hidden: { opacity: 0, y: 10 },
        visible: {
            opacity: 1,
            y: 0,
            transition: { duration: 0.5, staggerChildren: 0.1 },
        },
    }

    const fetchUsers = useCallback(async () => {
        try {
            setLoading(true)
            setError(null)

            const response = await axios.get(`${backendUrl}/admin/getAllUsers`, {
                headers: {
                    Authorization: `Bearer ${aToken}`,
                },
            })
            console.log('Fetch Users Response:', response.data)
            if (response.data?.status) {
                setUsers(response.data.data || [])
            } else {
                throw new Error('Failed to fetch users')
            }
        } catch (err) {
            const message = err.response?.data?.message || 'Failed to fetch users'
            setError(message)
            toast.error(message)
        } finally {
            setLoading(false)
        }
    }, [backendUrl, aToken])

    useEffect(() => {
        fetchUsers()
    }, [fetchUsers])

    const columns = useMemo(
        () => [
            { key: 'no', label: 'NO', width: 50 },
            { key: 'user_id', label: 'ID', width: 70 },
            { 
                key: 'profile_image', 
                label: 'Avatar', 
                width: 80,
                render: (value) => (
                    <img 
                        src={value} 
                        alt="Profile" 
                        style={{ width: 40, height: 40, borderRadius: '50%', objectFit: 'cover' }}
                        onError={(e) => { e.target.src = 'https://via.placeholder.com/40x40?text=U' }}
                    />
                )
            },
            { key: 'first_name', label: 'First Name', width: 120 },
            { key: 'last_name', label: 'Last Name', width: 120 },
            { key: 'email', label: 'Email', width: 200 },
            { key: 'phone_number', label: 'Phone Number', width: 200 },
            { key: 'sports', label: 'Sports & Skills', width: 250 },

            { key: 'created_at', label: 'Joined', width: 140 },
        ],
        []
    )

    const rows = useMemo(
        () =>
            users.map((user, index) => {
                const sportsText = user.sports?.map(sport => `${sport.sport_name} (${sport.skill_level})`).join(', ') || 'None'

                return {
                    no: index + 1,
                    user_id: user.user_id,
                    profile_image: user.profile_image || 'https://via.placeholder.com/40x40?text=U',
                    first_name: user.first_name || '—',
                    last_name: user.last_name || '—',
                    email: user.user_email || '—',
                    phone_number: user.phone_number ?? '—',
                    sports: sportsText,
                    created_at: user.created_at
                        ? new Date(user.created_at).toLocaleString()
                        : '—',
                }
            }),
        [users]
    )


    const handleDeleteClick = useCallback((row) => {
        const id = row.user_id
        if (!id) {
            toast.error('Unable to identify this user')
            return
        }

        setSelectedUser({ id, name: `${row.first_name} ${row.last_name}`.trim() })
        setOpenModal(true)
    }, [])

    const deleteUser = useCallback(async () => {
        if (!selectedUser.id) return

        try {
            setLoading(true)
            const response = await axios.delete(`${backendUrl}/admin/deleteUser/${selectedUser.id}`, {
                headers: {
                    Authorization: `Bearer ${aToken}`,
                },
            })

            if (response.data?.status) {
                toast.success('User deleted successfully')
                fetchUsers()
            } else {
                throw new Error('Failed to delete user')
            }
        } catch (err) {
            const message = err.response?.data?.message || 'Failed to delete user'
            toast.error(message)
        } finally {
            setLoading(false)
            setOpenModal(false)
            setSelectedUser({ id: null, name: '' })
        }
    }, [backendUrl, aToken, selectedUser.id, fetchUsers])

    const handleCancelDelete = useCallback(() => {
        setOpenModal(false)
        setSelectedUser({ id: null, name: '' })
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
                    onConfirm={deleteUser}
                    onCancel={handleCancelDelete}
                    confirmText="Delete"
                    cancelText="Cancel"
                    width={400}
                    minWidth={250}
                    color="danger"
                >
                    <Typography id="modal-desc" textColor="text.tertiary" sx={{ mb: 3 }}>
                        Are you sure you want to delete {selectedUser.name || 'this user'}?
                    </Typography>
                </Modal>

                <Box sx={{ mb: 3 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 1 }}>
                        <Box>
                            <Typography level="h2" sx={{ fontSize: { xs: '1.5rem', sm: '1.875rem', md: '2.25rem' } }}>
                                Users Management
                            </Typography>
                            <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                                View and manage all users in the platform
                            </Typography>
                        </Box>
                        <Button
                            variant="outlined"
                            color="neutral"
                            loading={loading}
                            onClick={fetchUsers}
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
                />
            </Box>
        </motion.div>
    )
}

export default UsersManagement