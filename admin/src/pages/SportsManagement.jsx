import React, { useEffect, useState, useCallback, useMemo } from 'react'
import Box from "@mui/joy/Box";
import { motion } from 'framer-motion';
import toast from 'react-hot-toast';
import DataTable from '../components/DataTable';
import Typography from "@mui/joy/Typography";
import Modal from '../components/Modalbox';
import FormControl from '@mui/joy/FormControl';
import FormLabel from '@mui/joy/FormLabel';
import Input from '@mui/joy/Input';
import { Button } from '@mui/joy';
import { useDispatch, useSelector } from 'react-redux';
import {
    addSport,
    deleteSport as deleteSportThunk,
    fetchSports,
    updateSport,
} from '../features/sports/sportsThunks';
import {
    selectSports,
    selectSportsError,
    selectSportsStatus,
} from '../features/sports/sportsSelectors';
import { clearSportsError } from '../features/sports/sportsSlice';

function SportsManagement() {
    const dispatch = useDispatch();
    const sports = useSelector(selectSports);
    const status = useSelector(selectSportsStatus);
    const error = useSelector(selectSportsError);
    const loading = status === 'loading';
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

    useEffect(() => {
        dispatch(fetchSports());
    }, [dispatch]);

    useEffect(() => {
        if (error) {
            toast.error(error);
            dispatch(clearSportsError());
        }
    }, [error, dispatch]);

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

    const handleDeleteSubmit = useCallback(async () => {
        if (!selectedSportId) return;

        try {
            await dispatch(deleteSportThunk(selectedSportId)).unwrap();
            toast.success('Sport deleted successfully');
            dispatch(fetchSports());
        } catch (err) {
            console.error('Failed to delete sport:', err);
        } finally {
            setOpenModal(false);
            setSelectedSportId(null);
        }
    }, [dispatch, selectedSportId]);

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
            await dispatch(updateSport({
                sportId: editingSport.sport_id,
                sportName: editFormData.sport_name.trim(),
            })).unwrap();
            toast.success('Sport updated successfully');
            dispatch(fetchSports());
            setOpenEditModal(false);
            setEditingSport(null);
            setEditFormData({ sport_name: '' });
        } catch (err) {
            console.error('Failed to update sport:', err);
        } finally {
        }
    }, [dispatch, editingSport, editFormData]);

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
            await dispatch(addSport(addFormData.sport_name.trim())).unwrap();
            toast.success('Sport added successfully');
            dispatch(fetchSports());
            setAddModalOpen(false);
            setAddFormData({ sport_name: '' });
        } catch (err) {
            console.error('Failed to add sport:', err);
        } finally {
        }
    }, [dispatch, addFormData]);

    const handleCancelAdd = useCallback(() => {
        setAddModalOpen(false);
        setAddFormData({ sport_name: '' });
    }, []);

    const actions = useMemo(() => [
        {
            label: 'Edit',
            color: 'warning',
            variant: 'soft',
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
                    onConfirm={handleDeleteSubmit}
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