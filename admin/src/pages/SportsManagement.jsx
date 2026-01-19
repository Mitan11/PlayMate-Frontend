import React, { useEffect, useState, useContext, useCallback, useMemo } from 'react'
import Box from "@mui/joy/Box";
import { motion } from 'framer-motion';
import axios from 'axios';
import toast from 'react-hot-toast';
import DataTable from '../components/DataTable';
import { AppContext } from '../context/AppContextProvider';
import Typography from "@mui/joy/Typography";
import Modal from '../components/Modalbox';
import FormControl from '@mui/joy/FormControl';
import FormLabel from '@mui/joy/FormLabel';
import Input from '@mui/joy/Input';
import { Button } from '@mui/joy';

function SportsManagement() {
    const { backendUrl, aToken } = useContext(AppContext);
    const [sports, setSports] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [openModal, setOpenModal] = useState(false);
    const [selectedSportId, setSelectedSportId] = useState(null);
    const [openEditModal, setOpenEditModal] = useState(false);
    const [editingSport, setEditingSport] = useState(null);
    const [editFormData, setEditFormData] = useState({ sport_name: '' });
    const [addModalOpen, setAddModalOpen] = useState(false);
    const [addFormData, setAddFormData] = useState({ sport_name: '' });

    const containerVariants = {
        hidden: { opacity: 0, y: 10 },
        visible: {
            opacity: 1,
            y: 0,
            transition: { duration: 0.5, staggerChildren: 0.1 },
        },
    };

    // Fetch sports data
    const fetchSports = useCallback(async () => {
        try {
            setLoading(true);
            setError(null);
            const response = await axios.get(`${backendUrl}/admin/getAllSports`, {
                headers: {
                    Authorization: `Bearer ${aToken}`,
                },
            });

            if (response.data?.status) {
                setSports(response.data.data || []);
            } else {
                throw new Error('Failed to fetch sports');
            }
        } catch (err) {
            const message = err.response?.data?.message || 'Failed to fetch sports';
            setError(message);
            toast.error(message);
        } finally {
            setLoading(false);
        }
    }, [backendUrl, aToken]);

    useEffect(() => {
        fetchSports();
    }, [fetchSports]);

    // Define columns
    const columns = useMemo(() => [
        { key: 'no', label: 'NO', width: 50 },
        { key: 'sport_id', label: 'ID', width: 80 },
        { key: 'sport_name', label: 'Sport Name', width: 200 },
        { key: 'created_at', label: 'Created Date', width: 200 },
    ], []);

    // Transform sports data for table
    const rows = useMemo(
        () => {
            let no = 1;
            return sports.map((sport) => ({
                no: no++,
                ...sport,
                created_at: new Date(sport.created_at).toLocaleDateString(),
            }));
        },
        [sports]
    );


    const handleDeleteClick = useCallback((sportId) => {
        setSelectedSportId(sportId);
        setOpenModal(true);
    }, []);

    const deleteSport = useCallback(async () => {
        if (!selectedSportId) return;

        try {
            setLoading(true);
            const response = await axios.delete(`${backendUrl}/admin/deleteSport/${selectedSportId}`, {
                headers: {
                    Authorization: `Bearer ${aToken}`,
                },
            });
            if (response.data?.status) {
                toast.success('Sport deleted successfully');
                fetchSports();
            }
            else {
                throw new Error('Failed to delete sport');
            }
        } catch (err) {
            const message = err.response?.data?.message || 'Failed to delete sport';
            toast.error(message);
        } finally {
            setLoading(false);
            setOpenModal(false);
            setSelectedSportId(null);
        }
    }, [backendUrl, aToken, selectedSportId, fetchSports]);

    const handleCancelDelete = useCallback(() => {
        setOpenModal(false);
        setSelectedSportId(null);
    }, []);

    const handleEditClick = useCallback((sport) => {
        setEditingSport(sport);
        setEditFormData({ sport_name: sport.sport_name });
        setOpenEditModal(true);
    }, []);

    const handleEditFormChange = useCallback((field, value) => {
        setEditFormData(prev => ({ ...prev, [field]: value }));
    }, []);

    const handleEditSubmit = useCallback(async () => {
        if (!editingSport || !editFormData.sport_name.trim()) {
            toast.error('Sport name is required');
            return;
        }

        try {
            setLoading(true);
            const response = await axios.patch(`${backendUrl}/admin/updateSport/${editingSport.sport_id}`, {
                sport_name: editFormData.sport_name.trim()
            }, {
                headers: {
                    Authorization: `Bearer ${aToken}`,
                },
            });

            if (response.data?.status) {
                toast.success('Sport updated successfully');
                fetchSports();
                setOpenEditModal(false);
                setEditingSport(null);
                setEditFormData({ sport_name: '' });
            } else {
                throw new Error('Failed to update sport');
            }
        } catch (err) {
            const message = err.response?.data?.message || 'Failed to update sport';
            toast.error(message);
        } finally {
            setLoading(false);
        }
    }, [backendUrl, aToken, editingSport, editFormData, fetchSports]);

    const handleCancelEdit = useCallback(() => {
        setOpenEditModal(false);
        setEditingSport(null);
        setEditFormData({ sport_name: '' });
    }, []);

    const handleAddClick = useCallback(() => {
        setAddFormData({ sport_name: '' });
        setAddModalOpen(true);
    }, []);

    const handleAddFormChange = useCallback((field, value) => {
        setAddFormData(prev => ({ ...prev, [field]: value }));
    }, []);

    const handleAddSubmit = useCallback(async () => {
        if (!addFormData.sport_name.trim()) {
            toast.error('Sport name is required');
            return;
        }

        try {
            setLoading(true);
            const response = await axios.post(`${backendUrl}/admin/addSport`, {
                sport_name: addFormData.sport_name.trim()
            }, {
                headers: {
                    Authorization: `Bearer ${aToken}`,
                },
            });

            if (response.data?.status) {
                toast.success('Sport added successfully');
                fetchSports();
                setAddModalOpen(false);
                setAddFormData({ sport_name: '' });
            } else {
                throw new Error('Failed to add sport');
            }
        } catch (err) {
            const message = err.response?.data?.message || 'Failed to add sport';
            toast.error(message);
        } finally {
            setLoading(false);
        }
    }, [backendUrl, aToken, addFormData, fetchSports]);

    const handleCancelAdd = useCallback(() => {
        setAddModalOpen(false);
        setAddFormData({ sport_name: '' });
    }, []);

    const actions = useMemo(() => [
        {
            label: 'Edit',
            onClick: (row) => handleEditClick(row),
        },
        {
            label: 'Delete',
            color: 'danger',
            variant: 'soft',
            onClick: (row) => handleDeleteClick(row.sport_id),
        },
    ], [handleEditClick, handleDeleteClick]);


    return (
        <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            style={{ width: "100%", maxWidth: "100%", overflowX: "hidden" }}
        >
            <Box sx={{ p: { xs: 1.5, sm: 2, md: 3 }, maxWidth: "100%", overflowX: "hidden" }}>
                {/* Delete Confirmation Modal */}
                <Modal
                    open={openModal}
                    setOpen={setOpenModal}
                    title="Confirm Delete"
                    onConfirm={deleteSport}
                    onCancel={handleCancelDelete}
                    confirmText="Delete"
                    cancelText="Cancel"
                    width={400}
                    minWidth={250}
                    color='danger'
                >
                    <Typography id="modal-desc" textColor="text.tertiary" sx={{ mb: 3 }}>
                        Are you sure you want to delete this sport?
                    </Typography>
                </Modal>

                {/* Edit Sport Modal */}
                <Modal
                    open={openEditModal}
                    setOpen={setOpenEditModal}
                    title="Edit Sport"
                    onConfirm={handleEditSubmit}
                    onCancel={handleCancelEdit}
                    confirmText="Update"
                    cancelText="Cancel"
                    width={600}
                    minWidth={400}
                    color='warning'
                >
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, minWidth: 300, marginBottom: 3 }}>
                        <FormControl>
                            <FormLabel>Sport Name</FormLabel>
                            <Input
                                placeholder="Enter sport name"
                                value={editFormData.sport_name}
                                onChange={(e) => handleEditFormChange('sport_name', e.target.value)}
                                required
                            />
                        </FormControl>
                    </Box>
                </Modal>
                {/* Add Sport Modal */}
                <Modal
                    open={addModalOpen}
                    setOpen={setAddModalOpen}
                    title="Add New Sport"
                    onConfirm={handleAddSubmit}
                    onCancel={handleCancelAdd}
                    confirmText="Add"
                    cancelText="Cancel"
                    width={600}
                    minWidth={400}
                >
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, minWidth: 300, marginBottom: 3 }}>
                        <FormControl>
                            <FormLabel>Sport Name</FormLabel>
                            <Input
                                placeholder="Enter sport name"
                                value={addFormData.sport_name}
                                onChange={(e) => handleAddFormChange('sport_name', e.target.value)}
                                required
                                autoFocus
                            />
                        </FormControl>
                    </Box>
                </Modal>
                <Box sx={{ mb: 3 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 1 }}>
                        <Box>
                            <Typography level="h2" sx={{ fontSize: { xs: "1.5rem", sm: "1.875rem", md: "2.25rem" } }}>
                                Sports Management
                            </Typography>
                            <Typography level="body-sm" sx={{ color: "neutral.500" }}>
                                Manage the sports available in your Application
                            </Typography>
                        </Box>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                            <Button
                                variant="solid"
                                color="primary"
                                disabled={loading}
                                onClick={handleAddClick}
                            >
                                Add Sport
                            </Button>
                            <Button
                                variant="outlined"
                                color="neutral"
                                loading={loading}
                                onClick={fetchSports}
                            >
                                Refresh
                            </Button>
                        </Box>
                    </Box>
                </Box>

                {error && (
                    <Box sx={{ color: 'danger.main', py: 2, px: 2, backgroundColor: 'danger.softBg', borderRadius: 'sm', mb: 2 }}>
                        {error}
                    </Box>
                )}

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

export default SportsManagement;