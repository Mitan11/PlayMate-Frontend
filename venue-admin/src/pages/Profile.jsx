import React, { useContext, useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { AppContext } from '../context/AppContextProvider';
import { useNavigate } from 'react-router';
import { motion } from 'framer-motion';
import { FiImage } from 'react-icons/fi';
import axios from 'axios';
import toast from 'react-hot-toast';
import {
    Box,
    Typography,
    Card,
    CardContent,
    Button,
    Input,
    FormControl,
    FormLabel,
    Grid,
    IconButton,
    Avatar,
    Chip,
    Stack,
    LinearProgress,
} from "@mui/joy";
import {
    FaCamera,
    FaPhone,
    FaMapMarkerAlt,
    FaBuilding,
    FaUser,
    FaEdit,
    FaTimes,
    FaSave,
    FaCalendarAlt,
    FaIdCard,
    FaShieldAlt,
    FaEnvelope,
    FaCheck,
} from "react-icons/fa";
import Preloader from '../components/Preloader';

function Profile() {
    const { venueOwner, backendUrl, token, setVenueOwner } = useContext(AppContext);
    const navigate = useNavigate();
    const setVenueOwnerRef = useRef(setVenueOwner);
    setVenueOwnerRef.current = setVenueOwner;

    const [profile, setProfile] = useState(null);
    const [editMode, setEditMode] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [imageFile, setImageFile] = useState(null);
    const [imagePreview, setImagePreview] = useState("");

    /* ================= FETCH PROFILE ================= */
    const profileDetails = useCallback(async () => {
        if (!venueOwner?.venue_id || !token) {
            toast.error("Authentication required");
            return;
        }

        try {
            setIsLoading(true);
            const res = await axios.get(
                `${backendUrl}/venue/profile/${venueOwner.venue_id}`,
                { headers: { Authorization: `Bearer ${token}` } }
            );

            const profileData = res.data.data;
            setProfile(profileData);
            setImagePreview(profileData?.venue?.profile_image || "");
            
            // Update venueOwner context to sync with latest profile data
            setVenueOwnerRef.current(prevVenueOwner => {
                const updatedVenueOwner = {
                    ...prevVenueOwner,
                    first_name: profileData?.venue?.first_name || prevVenueOwner?.first_name,
                    last_name: profileData?.venue?.last_name || prevVenueOwner?.last_name,
                    profile_image: profileData?.venue?.profile_image || prevVenueOwner?.profile_image,
                };
                localStorage.setItem("venue_owner", JSON.stringify(updatedVenueOwner));
                return updatedVenueOwner;
            });
        } catch (err) {
            toast.error("Failed to load profile");
            if (err.response?.status === 401) navigate('/login');
        } finally {
            setIsLoading(false);
        }
    }, [venueOwner?.venue_id, token, backendUrl, navigate]);

    /* ================= INPUT CHANGE ================= */
    const handleInputChange = useCallback((field, value) => {
        setProfile(prev => ({
            ...prev,
            venue: {
                ...prev.venue,
                [field]: value
            }
        }));
    }, []);

    /* ================= IMAGE CHANGE ================= */
    const handleImageChange = useCallback((e) => {
        const file = e.target.files[0];
        if (!file) return;

        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
            toast.error("Image size should be less than 5MB");
            return;
        }

        // Validate file type
        if (!file.type.startsWith('image/')) {
            toast.error("Please select a valid image file");
            return;
        }

        setImageFile(file);
        setImagePreview(URL.createObjectURL(file));
    }, []);

    /* ================= SAVE ================= */
    const handleSave = useCallback(async () => {
        try {
            setIsLoading(true);

            const dataToSend = {
                first_name: profile?.venue?.first_name,
                last_name: profile?.venue?.last_name,
                phone: profile?.venue?.phone,
                address: profile?.venue?.address,
                venue_name: profile?.venue?.venue_name
            };

            Object.keys(dataToSend).forEach(
                key => (!dataToSend[key]?.trim()) && delete dataToSend[key]
            );

            if (Object.keys(dataToSend).length === 0 && !imageFile) {
                toast.error("No changes to save");
                setIsLoading(false);
                return;
            }

            let requestData;
            let headers = { Authorization: `Bearer ${token}` };

            if (imageFile) {
                requestData = new FormData();
                Object.entries(dataToSend).forEach(([key, val]) => {
                    requestData.append(key, val);
                });
                requestData.append("profile_image", imageFile);
            } else {
                requestData = dataToSend;
                headers["Content-Type"] = "application/json";
            }

            const res = await axios.put(
                `${backendUrl}/venue/profile/${venueOwner.venue_id}`,
                requestData,
                { headers }
            );

            const updatedProfileData = res.data.data;
            setProfile(updatedProfileData);
            setImagePreview(updatedProfileData?.venue?.profile_image || "");
            
            // Update venueOwner context for navbar to reflect changes
            setVenueOwnerRef.current(prevVenueOwner => {
                const updatedVenueOwner = {
                    ...prevVenueOwner,
                    first_name: updatedProfileData?.venue?.first_name || prevVenueOwner?.first_name,
                    last_name: updatedProfileData?.venue?.last_name || prevVenueOwner?.last_name,
                    profile_image: updatedProfileData?.venue?.profile_image || prevVenueOwner?.profile_image,
                };
                localStorage.setItem("venue_owner", JSON.stringify(updatedVenueOwner));
                return updatedVenueOwner;
            });
            
            setEditMode(false);
            setImageFile(null);
            toast.success("Profile updated successfully");
        } catch (err) {
            toast.error("Failed to update profile");
        } finally {
            setIsLoading(false);
        }
    }, [profile, imageFile, token, backendUrl, venueOwner?.venue_id]);

    const handleCancelEdit = useCallback(() => {
        setEditMode(false);
        setImageFile(null);
        setImagePreview(profile?.venue?.profile_image || "");
        profileDetails();
    }, [profile?.venue?.profile_image, profileDetails]);

    // Memoized computed values
    const formattedJoinDate = useMemo(() => 
        profile?.venue?.created_at
            ? new Date(profile.venue.created_at).toLocaleDateString(undefined, {
                  year: "numeric",
                  month: "long",
                  day: "numeric"
              })
            : "—", 
        [profile?.venue?.created_at]
    );

    const fullName = useMemo(() => 
        `${profile?.venue?.first_name || ''} ${profile?.venue?.last_name || ''}`.trim() || 'Venue Owner',
        [profile?.venue?.first_name, profile?.venue?.last_name]
    );

    const profileFields = useMemo(() => [
        { key: "first_name", label: "First Name", icon: <FaUser />, required: true },
        { key: "last_name", label: "Last Name", icon: <FaUser />, required: true },
        { key: "email", label: "Email Address", icon: <FaEnvelope />, required: false, readonly: true },
        { key: "phone", label: "Phone Number", icon: <FaPhone />, required: false }
    ], []);

    useEffect(() => {
        document.title = "PlayMate | Profile";
        profileDetails();
    }, [profileDetails]);

    if (isLoading && !profile) return <Preloader />;

    if (!profile) {
        return (
            <Box sx={{ p: 3, textAlign: "center" }}>
                <Typography level="h4">No Profile Found</Typography>
                <Button onClick={profileDetails}>Retry</Button>
            </Box>
        );
    }

    /* ================= UI ================= */
    return (
        <Box sx={{ minHeight: '100vh', bgcolor: '#f8fafc' }}>
            {/* Header Section */}
            <Box sx={{ 
                bgcolor: 'white',
                borderBottom: '1px solid #e2e8f0',
                px: 3,
                py: 2
            }}>
                <Box sx={{ maxWidth: 1200, mx: 'auto' }}>
                    {/* Page Title */}
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                        <Box>
                            <Typography 
                                level="h2" 
                                sx={{ 
                                    color: '#1e293b',
                                    fontWeight: 700,
                                    mb: 1,
                                    fontSize: '1.875rem'
                                }}
                            >
                                Profile Settings
                            </Typography>
                            <Typography sx={{ color: '#64748b', fontSize: '1rem' }}>
                                Manage your account information and venue details
                            </Typography>
                        </Box>
                        
                        {!editMode && (
                            <Box sx={{ display: 'flex', gap: 2 }}>
                                <Button 
                                    variant="solid"
                                    color="primary"
                                    startDecorator={<FaEdit />}
                                    onClick={() => setEditMode(true)}
                                    sx={{
                                        borderRadius: '8px',
                                        px: 3,
                                        py: 1.5,
                                        fontWeight: 600,
                                        boxShadow: '0 1px 2px 0 rgb(0 0 0 / 0.05)'
                                    }}
                                >
                                    Edit Profile
                                </Button>
                                <Button 
                                    variant="soft"
                                    color="primary"
                                    startDecorator={<FiImage />}
                                    onClick={() => navigate('/venue-images')}
                                    sx={{
                                        borderRadius: '8px',
                                        px: 3,
                                        py: 1.5,
                                        fontWeight: 600,
                                        boxShadow: '0 1px 2px 0 rgb(0 0 0 / 0.05)'
                                    }}
                                >
                                    Venue Images
                                </Button>
                            </Box>
                        )}
                    </Box>

                    {/* Progress Indicator */}
                    {isLoading && (
                        <LinearProgress 
                            sx={{ 
                                mt: 2,
                                '--LinearProgress-radius': '4px'
                            }} 
                        />
                    )}
                </Box>
            </Box>

            {/* Main Content */}
            <Box sx={{ maxWidth: 1200, mx: 'auto', p: 3 }}>
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.4, ease: "easeOut" }}
                >
                    <Grid container spacing={3}>
                        {/* Profile Overview Card */}
                        <Grid xs={12} lg={4}>
                            <Card 
                                variant="outlined" 
                                sx={{ 
                                    bgcolor: 'white',
                                    border: '1px solid #e2e8f0',
                                    borderRadius: '12px',
                                    boxShadow: '0 1px 3px 0 rgb(0 0 0 / 0.1)',
                                    overflow: 'hidden'
                                }}
                            >
                                {/* Card Header */}
                                <Box sx={{ 
                                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                                    p: 3,
                                    position: 'relative'
                                }}>
                                    <Box sx={{
                                        position: 'absolute',
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        background: 'rgba(255,255,255,0.1)',
                                        backdropFilter: 'blur(10px)'
                                    }} />
                                    
                                    <Box sx={{ position: 'relative', textAlign: 'center' }}>
                                        {/* Avatar */}
                                        <Box sx={{ position: 'relative', display: 'inline-block', mb: 2 }}>
                                            <Avatar
                                                src={imagePreview}
                                                sx={{ 
                                                    width: 120, 
                                                    height: 120,
                                                    border: '4px solid rgba(255,255,255,0.3)',
                                                    boxShadow: '0 8px 32px rgba(0,0,0,0.1)',
                                                    mx: 'auto'
                                                }}
                                            >
                                                <FaUser size={48} color="rgba(255,255,255,0.7)" />
                                            </Avatar>
                                            
                                            {editMode && (
                                                <IconButton 
                                                    component="label"
                                                    variant="solid"
                                                    disabled={isLoading}
                                                    sx={{ 
                                                        position: 'absolute',
                                                        bottom: 8,
                                                        right: 8,
                                                        bgcolor: isLoading ? 'rgba(255,255,255,0.5)' : 'rgba(255,255,255,0.9)',
                                                        color: isLoading ? '#9ca3af' : '#667eea',
                                                        width: 40,
                                                        height: 40,
                                                        '&:hover': { 
                                                            bgcolor: isLoading ? 'rgba(255,255,255,0.5)' : 'white',
                                                            transform: isLoading ? 'none' : 'scale(1.05)'
                                                        },
                                                        boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                                                        transition: 'all 0.2s',
                                                        opacity: isLoading ? 0.5 : 1,
                                                        cursor: isLoading ? 'not-allowed' : 'pointer'
                                                    }}
                                                >
                                                    <FaCamera size={16} />
                                                    <input 
                                                        hidden 
                                                        type="file" 
                                                        accept="image/*" 
                                                        onChange={handleImageChange}
                                                        disabled={isLoading}
                                                    />
                                                </IconButton>
                                            )}
                                            
                                            {imageFile && (
                                                <motion.div
                                                    initial={{ scale: 0, opacity: 0 }}
                                                    animate={{ scale: 1, opacity: 1 }}
                                                    transition={{ type: "spring", duration: 0.5 }}
                                                >
                                                    <Chip 
                                                        variant="solid" 
                                                        color="success" 
                                                        size="sm"
                                                        sx={{ 
                                                            position: 'absolute', 
                                                            top: -8, 
                                                            left: '50%', 
                                                            transform: 'translateX(-50%)',
                                                            fontWeight: 600,
                                                            fontSize: '0.75rem'
                                                        }}
                                                    >
                                                        <FaCheck className='inline mr-1' /> Image Updated
                                                    </Chip>
                                                </motion.div>
                                            )}
                                        </Box>

                                        {/* User Info */}
                                        <Typography 
                                            level="h3" 
                                            sx={{ 
                                                color: 'white', 
                                                fontWeight: 700, 
                                                mb: 0.5,
                                                textShadow: '0 2px 4px rgba(0,0,0,0.2)'
                                            }}
                                        >
                                            {fullName}
                                        </Typography>
                                        <Typography sx={{ 
                                            color: 'rgba(255,255,255,0.9)', 
                                            fontSize: '0.875rem',
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            gap: 1
                                        }}>
                                            <FaCalendarAlt size={12} />
                                            Member since {formattedJoinDate}
                                        </Typography>
                                    </Box>
                                </Box>

                                {/* Quick Stats */}
                                <CardContent sx={{ p: 3 }}>
                                    <Stack spacing={2}>
                                        <Box sx={{ 
                                            display: 'flex', 
                                            justifyContent: 'space-between', 
                                            alignItems: 'center',
                                            p: 2,
                                            bgcolor: '#f8fafc',
                                            borderRadius: '8px'
                                        }}>
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                                <Box sx={{
                                                    bgcolor: '#dbeafe',
                                                    color: '#3b82f6',
                                                    p: 1,
                                                    borderRadius: '6px'
                                                }}>
                                                    <FaIdCard size={16} />
                                                </Box>
                                                <Typography level="body-sm" sx={{ color: '#64748b', fontWeight: 500 }}>
                                                    Venue ID
                                                </Typography>
                                            </Box>
                                            <Chip variant="outlined" color="primary" size="sm">
                                                #{profile?.venue?.venue_id}
                                            </Chip>
                                        </Box>

                                        <Box sx={{ 
                                            display: 'flex', 
                                            justifyContent: 'space-between', 
                                            alignItems: 'center',
                                            p: 2,
                                            bgcolor: '#f8fafc',
                                            borderRadius: '8px'
                                        }}>
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                                <Box sx={{
                                                    bgcolor: '#dcfce7',
                                                    color: '#16a34a',
                                                    p: 1,
                                                    borderRadius: '6px'
                                                }}>
                                                    <FaShieldAlt size={16} />
                                                </Box>
                                                <Typography level="body-sm" sx={{ color: '#64748b', fontWeight: 500 }}>
                                                    Status
                                                </Typography>
                                            </Box>
                                            <Chip variant="soft" color="success" size="sm">
                                                Active
                                            </Chip>
                                        </Box>
                                    </Stack>
                                </CardContent>
                            </Card>
                        </Grid>

                        {/* Forms Section */}
                        <Grid xs={12} lg={8}>
                            <Stack spacing={3}>
                                {/* Personal Information Card */}
                                <Card 
                                    variant="outlined" 
                                    sx={{ 
                                        bgcolor: 'white',
                                        border: '1px solid #e2e8f0',
                                        borderRadius: '12px',
                                        boxShadow: '0 1px 3px 0 rgb(0 0 0 / 0.1)'
                                    }}
                                >
                                    <CardContent sx={{ p: 4 }}>
                                        <Typography 
                                            level="h4" 
                                            sx={{ 
                                                color: '#1e293b',
                                                fontWeight: 600,
                                                mb: 3,
                                                display: 'flex',
                                                alignItems: 'center',
                                                gap: 2
                                            }}
                                        >
                                            <Box sx={{
                                                bgcolor: '#f1f5f9',
                                                color: '#475569',
                                                p: 1.5,
                                                borderRadius: '8px'
                                            }}>
                                                <FaUser size={18} />
                                            </Box>
                                            Personal Information
                                        </Typography>

                                        <Grid container spacing={3}>
                                            {profileFields.map(({ key, label, icon, required, readonly }) => {
                                                const inputId = `profile-${key}`;
                                                return (
                                                <Grid xs={12} sm={6} key={key}>
                                                    <FormControl>
                                                        <FormLabel 
                                                            htmlFor={inputId}
                                                            sx={{ 
                                                                color: '#374151',
                                                                fontWeight: 600,
                                                                mb: 1,
                                                                fontSize: '0.875rem'
                                                            }}
                                                        >
                                                            {label}
                                                            {required && (
                                                                <Typography component="span" sx={{ color: '#ef4444', ml: 0.5 }}>
                                                                    *
                                                                </Typography>
                                                            )}
                                                        </FormLabel>
                                                        {editMode && !readonly ? (
                                                            <Input
                                                                id={inputId}
                                                                value={profile.venue?.[key] || ""}
                                                                onChange={e => handleInputChange(key, e.target.value)}
                                                                placeholder={`Enter ${label.toLowerCase()}`}
                                                                disabled={isLoading}
                                                                startDecorator={React.cloneElement(icon, { 
                                                                    size: 16, 
                                                                    color: isLoading ? '#d1d5db' : '#9ca3af' 
                                                                })}
                                                                sx={{ 
                                                                    '--Input-focusedThickness': '2px',
                                                                    '--Input-focusedHighlight': '#3b82f6',
                                                                    borderRadius: '8px',
                                                                    fontSize: '0.875rem',
                                                                    py: 1.5,
                                                                    opacity: isLoading ? 0.6 : 1
                                                                }}
                                                            />
                                                        ) : (
                                                            <Box sx={{
                                                                display: 'flex',
                                                                alignItems: 'center',
                                                                gap: 2,
                                                                p: 2,
                                                                bgcolor: '#f8fafc',
                                                                border: '1px solid #e2e8f0',
                                                                borderRadius: '8px',
                                                                minHeight: '44px'
                                                            }}>
                                                                {React.cloneElement(icon, { 
                                                                    size: 16, 
                                                                    color: '#9ca3af' 
                                                                })}
                                                                <Typography sx={{ 
                                                                    color: profile.venue?.[key] ? '#1e293b' : '#9ca3af',
                                                                    fontSize: '0.875rem',
                                                                    fontStyle: !profile.venue?.[key] ? 'italic' : 'normal'
                                                                }}>
                                                                    {profile.venue?.[key] || 'Not provided'}
                                                                </Typography>
                                                            </Box>
                                                        )}
                                                    </FormControl>
                                                </Grid>
                                                );
                                            })}
                                        </Grid>
                                    </CardContent>
                                </Card>

                                {/* Venue Information Card */}
                                <Card 
                                    variant="outlined" 
                                    sx={{ 
                                        bgcolor: 'white',
                                        border: '1px solid #e2e8f0',
                                        borderRadius: '12px',
                                        boxShadow: '0 1px 3px 0 rgb(0 0 0 / 0.1)'
                                    }}
                                >
                                    <CardContent sx={{ p: 4 }}>
                                        <Typography 
                                            level="h4" 
                                            sx={{ 
                                                color: '#1e293b',
                                                fontWeight: 600,
                                                mb: 3,
                                                display: 'flex',
                                                alignItems: 'center',
                                                gap: 2
                                            }}
                                        >
                                            <Box sx={{
                                                bgcolor: '#f1f5f9',
                                                color: '#475569',
                                                p: 1.5,
                                                borderRadius: '8px'
                                            }}>
                                                <FaBuilding size={18} />
                                            </Box>
                                            Venue Information
                                        </Typography>

                                        <Grid container spacing={3}>
                                            <Grid xs={12} sm={6}>
                                                <FormControl>
                                                    <FormLabel 
                                                        htmlFor="venue-name-input"
                                                        sx={{ 
                                                            color: '#374151',
                                                            fontWeight: 600,
                                                            mb: 1,
                                                            fontSize: '0.875rem'
                                                        }}
                                                    >
                                                        Venue Name
                                                        <Typography component="span" sx={{ color: '#ef4444', ml: 0.5 }}>
                                                            *
                                                        </Typography>
                                                    </FormLabel>
                                                    {editMode ? (
                                                        <Input
                                                            id="venue-name-input"
                                                            value={profile.venue?.venue_name || ""}
                                                            onChange={e => handleInputChange("venue_name", e.target.value)}
                                                            placeholder="Enter venue name"
                                                            disabled={isLoading}
                                                            startDecorator={<FaBuilding size={16} color={isLoading ? '#d1d5db' : '#9ca3af'} />}
                                                            sx={{ 
                                                                '--Input-focusedThickness': '2px',
                                                                '--Input-focusedHighlight': '#3b82f6',
                                                                borderRadius: '8px',
                                                                fontSize: '0.875rem',
                                                                py: 1.5,
                                                                opacity: isLoading ? 0.6 : 1
                                                            }}
                                                        />
                                                    ) : (
                                                        <Box sx={{
                                                            display: 'flex',
                                                            alignItems: 'center',
                                                            gap: 2,
                                                            p: 2,
                                                            bgcolor: '#f8fafc',
                                                            border: '1px solid #e2e8f0',
                                                            borderRadius: '8px',
                                                            minHeight: '44px'
                                                        }}>
                                                            <FaBuilding size={16} color="#9ca3af" />
                                                            <Typography sx={{ 
                                                                color: profile.venue?.venue_name ? '#1e293b' : '#9ca3af',
                                                                fontSize: '0.875rem',
                                                                fontWeight: profile.venue?.venue_name ? 600 : 400,
                                                                fontStyle: !profile.venue?.venue_name ? 'italic' : 'normal'
                                                            }}>
                                                                {profile.venue?.venue_name || 'Not provided'}
                                                            </Typography>
                                                        </Box>
                                                    )}
                                                </FormControl>
                                            </Grid>

                                            <Grid xs={12} sm={6}>
                                                <FormControl>
                                                    <FormLabel 
                                                        htmlFor="email-address-input"
                                                        sx={{ 
                                                            color: '#374151',
                                                            fontWeight: 600,
                                                            mb: 1,
                                                            fontSize: '0.875rem'
                                                        }}
                                                    >
                                                        Email Address
                                                    </FormLabel>
                                                    <Box 
                                                        id="email-address-input"
                                                        sx={{
                                                            display: 'flex',
                                                            alignItems: 'center',
                                                            gap: 2,
                                                            p: 2,
                                                            bgcolor: '#f8fafc',
                                                            border: '1px solid #e2e8f0',
                                                            borderRadius: '8px',
                                                            minHeight: '44px'
                                                        }}
                                                    >
                                                        <FaEnvelope size={16} color="#9ca3af" />
                                                        <Typography sx={{ 
                                                            color: profile.venue?.email ? '#1e293b' : '#9ca3af',
                                                            fontSize: '0.875rem',
                                                            fontStyle: !profile.venue?.email ? 'italic' : 'normal'
                                                        }}>
                                                            {profile.venue?.email || 'Not provided'}
                                                        </Typography>
                                                    </Box>
                                                </FormControl>
                                            </Grid>

                                            <Grid xs={12}>
                                                <FormControl>
                                                    <FormLabel 
                                                        htmlFor="venue-address-input"
                                                        sx={{ 
                                                            color: '#374151',
                                                            fontWeight: 600,
                                                            mb: 1,
                                                            fontSize: '0.875rem'
                                                        }}
                                                    >
                                                        Venue Address
                                                    </FormLabel>
                                                    {editMode ? (
                                                        <Input
                                                            id="venue-address-input"
                                                            value={profile.venue?.address || ""}
                                                            onChange={e => handleInputChange("address", e.target.value)}
                                                            placeholder="Enter venue address"
                                                            disabled={isLoading}
                                                            startDecorator={<FaMapMarkerAlt size={16} color={isLoading ? '#d1d5db' : '#9ca3af'} />}
                                                            sx={{ 
                                                                '--Input-focusedThickness': '2px',
                                                                '--Input-focusedHighlight': '#3b82f6',
                                                                borderRadius: '8px',
                                                                fontSize: '0.875rem',
                                                                py: 1.5,
                                                                opacity: isLoading ? 0.6 : 1
                                                            }}
                                                        />
                                                    ) : (
                                                        <Box 
                                                            id="venue-address-input"
                                                            sx={{
                                                                display: 'flex',
                                                                alignItems: 'center',
                                                                gap: 2,
                                                                p: 2,
                                                                bgcolor: '#f8fafc',
                                                                border: '1px solid #e2e8f0',
                                                                borderRadius: '8px',
                                                                minHeight: '44px'
                                                            }}
                                                        >
                                                            <FaMapMarkerAlt size={16} color="#9ca3af" />
                                                            <Typography sx={{ 
                                                                color: profile.venue?.address ? '#1e293b' : '#9ca3af',
                                                                fontSize: '0.875rem',
                                                                fontStyle: !profile.venue?.address ? 'italic' : 'normal'
                                                            }}>
                                                                {profile.venue?.address || 'Not provided'}
                                                            </Typography>
                                                        </Box>
                                                    )}
                                                </FormControl>
                                            </Grid>
                                        </Grid>
                                    </CardContent>
                                </Card>

                                {/* Action Buttons */}
                                {editMode && (
                                    <motion.div
                                        initial={{ opacity: 0, y: 10 }}
                                        animate={{ opacity: 1, y: 0 }}
                                        transition={{ duration: 0.3 }}
                                    >
                                        <Card 
                                            variant="outlined" 
                                            sx={{ 
                                                bgcolor: 'white',
                                                border: '1px solid #e2e8f0',
                                                borderRadius: '12px',
                                                boxShadow: '0 1px 3px 0 rgb(0 0 0 / 0.1)'
                                            }}
                                        >
                                            <CardContent sx={{ p: 3 }}>
                                                <Stack direction="row" spacing={2} justifyContent="flex-end">
                                                    <Button 
                                                        variant="outlined" 
                                                        color="neutral"
                                                        onClick={handleCancelEdit} 
                                                        startDecorator={<FaTimes />}
                                                        disabled={isLoading}
                                                        sx={{ 
                                                            borderRadius: '8px',
                                                            px: 3,
                                                            py: 1.5,
                                                            fontWeight: 600
                                                        }}
                                                    >
                                                        Cancel
                                                    </Button>
                                                    <Button 
                                                        variant="solid"
                                                        color="primary"
                                                        onClick={handleSave} 
                                                        loading={isLoading} 
                                                        startDecorator={!isLoading && <FaSave />}
                                                        sx={{ 
                                                            borderRadius: '8px',
                                                            px: 3,
                                                            py: 1.5,
                                                            fontWeight: 600,
                                                            boxShadow: '0 1px 2px 0 rgb(0 0 0 / 0.05)'
                                                        }}
                                                    >
                                                        {isLoading ? 'Saving Changes...' : 'Save Changes'}
                                                    </Button>
                                                </Stack>
                                            </CardContent>
                                        </Card>
                                    </motion.div>
                                )}
                            </Stack>
                        </Grid>
                    </Grid>
                </motion.div>
            </Box>
        </Box>
    );
}

export default Profile;