import React, { useState, useEffect, useRef, useContext, useCallback } from 'react';
import { motion } from 'framer-motion';
import Box from '@mui/joy/Box';
import Card from '@mui/joy/Card';
import Typography from '@mui/joy/Typography';
import Button from '@mui/joy/Button';
import Grid from '@mui/joy/Grid';
import Skeleton from '@mui/joy/Skeleton';
import { FiTrash2, FiPlus, FiUpload } from 'react-icons/fi';
import { AppContext } from '../context/AppContextProvider';
import axios from 'axios';
import toast from 'react-hot-toast';

function VenueImages() {
    const { backendUrl, token, venueOwner } = useContext(AppContext);
    const [images, setImages] = useState([]);
    const [hoveredImage, setHoveredImage] = useState(null);
    const [uploading, setUploading] = useState(false);
    const [loading, setLoading] = useState(false);
    const fileInputRef = useRef(null);

    const fetchVenueImages = useCallback(async () => {
        if (!backendUrl || !token || !venueOwner?.venue_id) {
            setImages([]);
            return;
        }

        setLoading(true);
        try {
            const response = await axios.get(
                `${backendUrl}/venue/venueImages/${venueOwner.venue_id}`,
                {
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                }
            );
            
            if (response.data.status && Array.isArray(response.data.data)) {
                const mapped = response.data.data
                    .map((item, index) => {
                        const url = item.image_url || item.venue_image || item.url;
                        if (!url) return null;
                        return {
                            id: item.venue_image_id || item.id || item.image_id || index + 1,
                            title: item.title || `Image ${index + 1}`,
                            url,
                            uploadedDate: item.created_at
                                ? new Date(item.created_at).toISOString().split('T')[0]
                                : '—'
                        };
                    })
                    .filter(Boolean);

                setImages(mapped.length ? mapped : []);
            } else {
                setImages([]);
            }
        } catch (error) {
            console.error('Fetch venue images error:', error);
            setImages([]);
        } finally {
            setLoading(false);
        }
    }, [backendUrl, token, venueOwner?.venue_id]);

    useEffect(() => {
        document.title = 'PlayMate | Venue Images';
        fetchVenueImages();
    }, [fetchVenueImages]);

    const handleDelete = async (id) => {
        const target = images.find(img => img.id === id);
        if (!target || target.isPending) return;

        // Optimistic UI update
        setImages(prev => prev.filter(img => img.id !== id));

        if (!backendUrl || !token) return;

        try {
            await axios.delete(`${backendUrl}/venue/venueImage/${id}`, {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            });
            toast.success('Image deleted successfully');
            fetchVenueImages();
        } catch (error) {
            console.error('Delete image error:', error);
            toast.error('Failed to delete image');
            // Revert if delete failed
            fetchVenueImages();
        }
    };

    const handleUploadClick = () => {
        fileInputRef.current?.click();
    };

    const handleView = (url) => {
        if (!url) return;
        window.open(url, '_blank', 'noopener,noreferrer');
    };

    const handleFileSelect = async (event) => {
        const files = event.target.files;
        if (!files || files.length === 0) return;

        const file = files[0];

        // Validate file type
        const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
        if (!validTypes.includes(file.type)) {
            toast.error('Please upload a valid image file (JPEG, PNG, GIF, or WebP)');
            return;
        }

        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
            toast.error('File size must be less than 5MB');
            return;
        }

        // Validate orientation: allow only landscape images
        const isLandscape = await new Promise((resolve) => {
            const img = new Image();
            const objectUrl = URL.createObjectURL(file);
            img.onload = () => {
                const landscape = img.width > img.height;
                URL.revokeObjectURL(objectUrl);
                resolve(landscape);
            };
            img.onerror = () => {
                URL.revokeObjectURL(objectUrl);
                resolve(false);
            };
            img.src = objectUrl;
        });

        if (!isLandscape) {
            toast.error('Please upload landscape images only');
            return;
        }

        setUploading(true);
        const tempId = `temp-${Date.now()}`;
        const pendingImage = {
            id: tempId,
            title: file.name.split('.')[0],
            url: null,
            uploadedDate: 'Uploading...',
            isPending: true
        };
        setImages(prev => [pendingImage, ...prev]);

        try {
            // Create FormData for multipart upload
            const formData = new FormData();
            formData.append('venue_image', file);
            formData.append('title', file.name.split('.')[0]);

            // Send to backend and refresh list
            await sendImageToBackend(formData);
            await fetchVenueImages();
        } catch (error) {
            console.error('Upload error:', error);
            toast.error('Failed to upload image');
            // Remove pending placeholder on error
            setImages(prev => prev.filter(img => img.id !== tempId));
        } finally {
            setUploading(false);
        }

        // Reset input
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    const sendImageToBackend = async (formData) => {
        try {
            if (!backendUrl || !token || !venueOwner?.venue_id) {
                console.log('Missing backend configuration');
                return;
            }

            const response = await axios.post(
                `${backendUrl}/venue/venueImage/upload/${venueOwner.venue_id}`,
                formData,
                {
                    headers: {
                        Authorization: `Bearer ${token}`,
                        'Content-Type': 'multipart/form-data'
                    }
                }
            );

            if (response.data.status) {
                toast.success(response.data.message || 'Image uploaded successfully');
            } else {
                console.warn('Backend response:', response.data);
            }
        } catch (error) {
            console.error('Backend upload error:', error);
            if (error.response?.status === 401) {
                toast.error('Unauthorized - Please login again');
            } else if (error.response?.status === 413) {
                toast.error('File size too large');
            } else if (error.response?.status === 400) {
                toast.error(error.response?.data?.message || 'Bad request');
            } else {
                console.log('Note: Backend upload failed, but image is displayed locally');
            }
        }
    };

    const containerVariants = {
        hidden: { opacity: 0, y: 10 },
        visible: {
            opacity: 1,
            y: 0,
            transition: { duration: 0.5, staggerChildren: 0.1 },
        },
    };

    const itemVariants = {
        hidden: { opacity: 0, y: 10 },
        visible: { opacity: 1, y: 0 },
    };

    return (
        <motion.div
            initial="hidden"
            animate="visible"
            variants={containerVariants}
            style={{ width: '100%', padding: '20px' }}
        >
            <Box
                sx={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    marginBottom: '30px',
                    flexWrap: 'wrap',
                    gap: 2,
                }}
            >
                <Box>
                    <Typography
                        level="h1"
                        sx={{
                            fontSize: '2rem',
                            fontWeight: 'bold',
                            color: '#1a1a1a',
                            marginBottom: '8px',
                        }}
                    >
                        Venue Images
                    </Typography>
                    <Typography
                        level="body-sm"
                        sx={{ color: '#666' }}
                    >
                        Manage and showcase your venue gallery
                    </Typography>
                </Box>
                <Button
                    startDecorator={uploading ? undefined : <FiPlus />}
                    onClick={handleUploadClick}
                    disabled={uploading}
                    sx={{
                        backgroundColor: '#007bff',
                        color: 'white',
                        textTransform: 'none',
                        padding: '8px 20px',
                        fontSize: '1rem',
                        '&:hover': {
                            backgroundColor: '#0056b3',
                        },
                        '&:disabled': {
                            backgroundColor: '#6c757d',
                            opacity: 0.6,
                        },
                    }}
                >
                    {uploading ? 'Uploading...' : 'Upload Image'}
                </Button>

                {/* Hidden File Input */}
                <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleFileSelect}
                    style={{ display: 'none' }}
                />
            </Box>

            {loading && (
                <Grid
                    container
                    spacing={2}
                    sx={{
                        display: 'grid',
                        gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
                        gap: '20px',
                        marginTop: '10px',
                    }}
                >
                    {[1, 2, 3, 4].map((item) => (
                        <Card key={item} sx={{ p: 0, overflow: 'hidden' }}>
                            <Skeleton variant="rectangular" sx={{ width: '100%', paddingTop: '75%' }} />
                            <Box sx={{ p: 2 }}>
                                <Skeleton variant="text" level="h4" width="60%" />
                                <Skeleton variant="text" level="body-sm" width="40%" />
                            </Box>
                        </Card>
                    ))}
                </Grid>
            )}

            {!loading && images.length === 0 ? (
                <Card
                    sx={{
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        justifyContent: 'center',
                        padding: '60px 20px',
                        textAlign: 'center',
                        backgroundColor: '#f5f5f5',
                        borderRadius: '12px',
                        border: '2px dashed #ccc',
                    }}
                >
                    <Typography
                        level="h3"
                        sx={{ marginBottom: '10px', color: '#666' }}
                    >
                        No Images Yet
                    </Typography>
                    <Typography
                        level="body-sm"
                        sx={{ color: '#999', marginBottom: '20px' }}
                    >
                        Upload your first venue image to get started
                    </Typography>
                    <Button
                        startDecorator={<FiPlus />}
                        onClick={handleUploadClick}
                        disabled={uploading}
                        sx={{
                            backgroundColor: '#007bff',
                            color: '#fff',
                            textTransform: 'none',
                            '&:disabled': {
                                backgroundColor: '#6c757d',
                                opacity: 0.6,
                            },
                        }}
                    >
                        {uploading ? 'Uploading...' : 'Upload Image'}
                    </Button>
                </Card>
            ) : (
                <Box
                    sx={{
                        columnCount: {
                            xs: 1,
                            sm: 1,
                            md: 2,
                            lg: 3,
                        },
                        columnGap: '18px',
                        width: '100%',
                    }}
                >
                    {images.map((image, index) => (
                        <motion.div
                            key={image.id}
                            variants={itemVariants}
                            style={{
                                breakInside: 'avoid',
                                display: 'inline-block',
                                width: '100%',
                                marginBottom: '16px',
                            }}
                        >
                            {(() => {
                                const isPending = image.isPending;
                                return (
                            <Card
                                sx={{
                                    display: 'flex',
                                    flexDirection: 'column',
                                    overflow: 'hidden',
                                    border: '1px solid #e0e0e0',
                                    borderRadius: '10px',
                                    transition: 'all 0.3s ease',
                                    boxShadow: '0 10px 30px rgba(0,0,0,0.08)',
                                    '&:hover': {
                                        boxShadow: '0 14px 36px rgba(0,0,0,0.12)',
                                        transform: 'translateY(-4px)',
                                    },
                                }}
                            >
                                {/* Image Container */}
                                <Box
                                    sx={{
                                        position: 'relative',
                                        width: '100%',
                                        overflow: 'hidden',
                                        backgroundColor: '#f0f0f0',
                                    }}
                                    onMouseEnter={() => !isPending && setHoveredImage(image.id)}
                                    onMouseLeave={() => setHoveredImage(null)}
                                >
                                    {isPending ? (
                                        <Skeleton
                                            variant="rectangular"
                                            sx={{ width: '100%', height: 220, display: 'block' }}
                                        />
                                    ) : (
                                        <Box
                                            component="img"
                                            src={image.url}
                                            alt={image.title}
                                            sx={{
                                                width: '100%',
                                                display: 'block',
                                                objectFit: 'cover',
                                            }}
                                        />
                                    )}

                                    {/* Hover Overlay */}
                                    {!isPending && hoveredImage === image.id && (
                                        <motion.div
                                            initial={{ opacity: 0 }}
                                            animate={{ opacity: 1 }}
                                            exit={{ opacity: 0 }}
                                            style={{
                                                position: 'absolute',
                                                top: 0,
                                                left: 0,
                                                width: '100%',
                                                height: '100%',
                                                backgroundColor: 'rgba(0, 0, 0, 0.5)',
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center',
                                                gap: '10px',
                                            }}
                                        >
                                            <Button
                                                startDecorator={<FiUpload />}
                                                onClick={() => handleView(image.url)}
                                                sx={{
                                                    backgroundColor: '#fff',
                                                    color: '#007bff',
                                                    padding: '6px 12px',
                                                    fontSize: '0.85rem',
                                                    '&:hover': {
                                                        backgroundColor: '#f0f0f0',
                                                    },
                                                }}
                                            >
                                                View
                                            </Button>
                                            <Button
                                                startDecorator={<FiTrash2 />}
                                                onClick={() => handleDelete(image.id)}
                                                sx={{
                                                    backgroundColor: '#ff4444',
                                                    color: '#fff',
                                                    padding: '6px 12px',
                                                    fontSize: '0.85rem',
                                                    '&:hover': {
                                                        backgroundColor: '#cc0000',
                                                    },
                                                }}
                                            >
                                                Delete
                                            </Button>
                                        </motion.div>
                                    )}

                                    {isPending && (
                                        <Box
                                            sx={{
                                                position: 'absolute',
                                                top: 0,
                                                left: 0,
                                                width: '100%',
                                                height: '100%',
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center',
                                                backgroundColor: 'rgba(0,0,0,0.45)',
                                                color: '#fff',
                                                fontWeight: 600,
                                                letterSpacing: 0.3,
                                            }}
                                        >
                                            Uploading...
                                        </Box>
                                    )}
                                </Box>

                                {/* Image Details */}
                                <Box sx={{ padding: '12px 14px 16px', display: 'flex', flexDirection: 'column', gap: '4px' }}>
                                    <Typography
                                        level="title-md"
                                        sx={{
                                            fontWeight: 700,
                                            color: '#1a1a1a',
                                            lineHeight: 1.3,
                                        }}
                                    >
                                        {image.title}
                                    </Typography>

                                    <Typography level="body-xs" sx={{ color: '#666' }}>
                                        <strong>Uploaded:</strong> {image.uploadedDate}
                                    </Typography>

                                    {/* Mobile Action Buttons (View + Delete) */}
                                    <Box
                                        sx={{
                                            display: 'none',
                                            gap: '8px',
                                            marginTop: '8px',
                                            '@media (max-width: 768px)': {
                                                display: 'flex',
                                            },
                                        }}
                                    >
                                        <Button
                                            startDecorator={<FiUpload size={14} />}
                                            onClick={() => handleView(image.url)}
                                            size="sm"
                                            sx={{
                                                flex: 1,
                                                backgroundColor: '#ffffff',
                                                color: '#007bff',
                                                fontSize: '0.75rem',
                                                border: '1px solid #e0e0e0',
                                            }}
                                            disabled={isPending}
                                        >
                                            View
                                        </Button>
                                        <Button
                                            startDecorator={<FiTrash2 size={14} />}
                                            onClick={() => handleDelete(image.id)}
                                            size="sm"
                                            sx={{
                                                flex: 1,
                                                backgroundColor: '#ff4444',
                                                color: '#fff',
                                                fontSize: '0.75rem',
                                            }}
                                            disabled={isPending}
                                        >
                                            Delete
                                        </Button>
                                    </Box>
                                </Box>
                            </Card>
                                );
                            })()}
                        </motion.div>
                    ))}
                </Box>
            )}

            {/* Stats Section removed (size and storage no longer displayed) */}
        </motion.div>
    );
}

export default VenueImages;
