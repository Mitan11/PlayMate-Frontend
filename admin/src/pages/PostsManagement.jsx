import React, { useCallback, useContext, useEffect, useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import axios from 'axios'
import toast from 'react-hot-toast'
import Box from '@mui/joy/Box'
import Typography from '@mui/joy/Typography'
import Button from '@mui/joy/Button'
import Chip from '@mui/joy/Chip'
import DataTable from '../components/DataTable'
import Modal from '../components/Modalbox'
import { AppContext } from '../context/AppContextProvider'
import { assets } from '../assets/assets';

function PostsManagement() {
    const { backendUrl, aToken } = useContext(AppContext)

    const [posts, setPosts] = useState([])
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState(null)
    const [openDeleteModal, setOpenDeleteModal] = useState(false)
    const [openViewModal, setOpenViewModal] = useState(false)
    const [selectedPost, setSelectedPost] = useState({ id: null, content: '' })
    const [viewingPost, setViewingPost] = useState(null)

    const containerVariants = {
        hidden: { opacity: 0, y: 10 },
        visible: {
            opacity: 1,
            y: 0,
            transition: { duration: 0.5, staggerChildren: 0.1 },
        },
    }

    const fetchPosts = useCallback(async () => {
        try {
            setLoading(true)
            setError(null)

            const response = await axios.get(`${backendUrl}/admin/getAllPosts`, {
                headers: {
                    Authorization: `Bearer ${aToken}`,
                },
            })

            if (response.data?.status) {
                setPosts(response.data.data || [])
            } else {
                throw new Error('Failed to fetch posts')
            }
        } catch (err) {
            const message = err.response?.data?.message || 'Failed to fetch posts'
            setError(message)
            toast.error(message)
        } finally {
            setLoading(false)
        }
    }, [backendUrl, aToken])

    useEffect(() => {
        fetchPosts()
    }, [fetchPosts])

    const columns = useMemo(
        () => [
            { key: 'no', label: 'NO', width: 50 },
            { key: 'post_id', label: 'Post ID', width: 80 },
            {
                key: 'profile_image',
                label: 'User Avatar',
                width: 90,
                render: (value) => (
                    <img
                        src={value}
                        alt="Profile"
                        style={{ width: 40, height: 40, borderRadius: '50%', objectFit: 'cover' }}
                        onError={(e) => { e.target.src = 'https://via.placeholder.com/40x40?text=U' }}
                    />
                )
            },
            { key: 'user_name', label: 'User Name', width: 140 },
            {
                key: 'text_content',
                label: 'Content',
                width: 300,
                render: (value, row) => (
                    <Box
                        sx={{
                            cursor: 'pointer',
                            '&:hover': { textDecoration: 'underline' },
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            whiteSpace: 'nowrap',
                            maxWidth: '280px'
                        }}
                        onClick={() => handleViewPost(row)}
                    >
                        {value || 'No content'}
                    </Box>
                )
            },
            {
                key: 'has_media',
                label: 'Media',
                width: 80,
                render: (value) => (
                    <Chip
                        color={value ? 'success' : 'neutral'}
                        size="sm"
                        variant="soft"
                    >
                        {value ? 'Yes' : 'No'}
                    </Chip>
                )
            },
            {
                key: 'like_count',
                label: 'Likes',
                width: 80,
                render: (value) => (
                    <Chip color="primary" size="sm" variant="soft">
                        {value || 0}
                    </Chip>
                )
            },
            { key: 'created_at', label: 'Posted', width: 140 },
        ],
        []
    )

    const rows = useMemo(
        () =>
            posts.map((post, index) => ({
                no: index + 1,
                post_id: post.post_id,
                profile_image: post.profile_image || 'https://via.placeholder.com/40x40?text=U',
                user_name: `${post.first_name || ''} ${post.last_name || ''}`.trim() || '—',
                text_content: post.text_content || 'No content',
                has_media: Boolean(post.media_url),
                like_count: post.like_count || 0,
                created_at: post.created_at
                    ? new Date(post.created_at).toLocaleString()
                    : '—',
                // Keep original data for modals
                originalPost: post
            })),
        [posts]
    )

    const handleViewPost = useCallback((row) => {
        setViewingPost(row.originalPost)
        setOpenViewModal(true)
    }, [])

    const handleDeleteClick = useCallback((row) => {
        const id = row.post_id
        if (!id) {
            toast.error('Unable to identify this post')
            return
        }

        setSelectedPost({
            id,
            content: row.text_content.length > 50
                ? row.text_content.substring(0, 50) + '...'
                : row.text_content
        })
        setOpenDeleteModal(true)
    }, [])

    const deletePost = useCallback(async () => {
        if (!selectedPost.id) return

        try {
            setLoading(true)
            const response = await axios.delete(`${backendUrl}/admin/deletePost/${selectedPost.id}`, {
                headers: {
                    Authorization: `Bearer ${aToken}`,
                },
            })

            if (response.data?.status) {
                toast.success('Post deleted successfully')
                fetchPosts()
            } else {
                throw new Error('Failed to delete post')
            }
        } catch (err) {
            const message = err.response?.data?.message || 'Failed to delete post'
            toast.error(message)
        } finally {
            setLoading(false)
            setOpenDeleteModal(false)
            setSelectedPost({ id: null, content: '' })
        }
    }, [backendUrl, aToken, selectedPost.id, fetchPosts])

    const handleCancelDelete = useCallback(() => {
        setOpenDeleteModal(false)
        setSelectedPost({ id: null, content: '' })
    }, [])

    const actions = useMemo(
        () => [
            {
                label: 'View',
                color: 'primary',
                variant: 'soft',
                onClick: (row) => handleViewPost(row),
            },
            {
                label: 'Delete',
                color: 'danger',
                variant: 'soft',
                onClick: (row) => handleDeleteClick(row),
            },
        ],
        [handleViewPost, handleDeleteClick]
    )

    return (
        <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            style={{ width: '100%', maxWidth: '100%', overflowX: 'hidden' }}
        >
            <Box sx={{ p: { xs: 1.5, sm: 2, md: 3 }, maxWidth: '100%', overflowX: 'hidden' }}>
                {/* Delete Confirmation Modal */}
                <Modal
                    open={openDeleteModal}
                    setOpen={setOpenDeleteModal}
                    title="Confirm Delete"
                    onConfirm={deletePost}
                    onCancel={handleCancelDelete}
                    confirmText="Delete"
                    cancelText="Cancel"
                    width={400}
                    minWidth={250}
                    color="danger"
                >
                    <Typography id="modal-desc" textColor="text.tertiary" sx={{ mb: 3 }}>
                        Are you sure you want to delete this post: "{selectedPost.content}"?
                    </Typography>
                </Modal>

                {/* Post View Modal */}
                <Modal
                    open={openViewModal}
                    setOpen={setOpenViewModal}
                    title="Post Details"
                    onCancel={() => setOpenViewModal(false)}
                    cancelText="Close"
                    width={600}
                    minWidth={400}
                >
                    {viewingPost && (
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                            {/* User Info */}
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                <img
                                    src={viewingPost.profile_image}
                                    alt="Profile"
                                    style={{ width: 50, height: 50, borderRadius: '50%', objectFit: 'cover' }}
                                    onError={(e) => { e.target.src = 'https://via.placeholder.com/50x50?text=U' }}
                                />
                                <Box>
                                    <Typography level="h4">
                                        {viewingPost.first_name} {viewingPost.last_name}
                                    </Typography>
                                    <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                                        {new Date(viewingPost.created_at).toLocaleString()}
                                    </Typography>
                                </Box>
                            </Box>

                            {/* Post Content */}
                            <Box sx={{ my: 2 }}>
                                <Typography level="body-md" sx={{ lineHeight: 1.6 }}>
                                    {viewingPost.text_content || 'No text content'}
                                </Typography>
                            </Box>

                            {/* Post Media */}
                            {viewingPost.media_url && (
                                <Box sx={{ mt: 2 }}>
                                    <img
                                        src={viewingPost.media_url}
                                        alt="Post content"
                                        style={{
                                            width: '100%',
                                            maxHeight: '400px',
                                            objectFit: 'contain',
                                            borderRadius: '8px',
                                            border: '1px solid #e0e0e0'
                                        }}
                                        onError={(e) => { e.target.style.display = 'none' }}
                                    />
                                </Box>
                            )}

                            {/* Post Stats */}
                            <Box sx={{ display: 'flex', gap: 2, mt: 2 }}>
                                <Chip color="primary" size="md" variant="soft">
                                    <img src={assets.like_icon} alt="Likes" style={{ width: 16, height: 16, marginRight: 4, display: viewingPost.like_count ? 'inline' : 'none' }} />
                                    {viewingPost.like_count || 0} likes
                                </Chip>
                                <Chip color="neutral" size="md" variant="soft">
                                    Post ID: {viewingPost.post_id}
                                </Chip>
                            </Box>
                        </Box>
                    )}
                </Modal>

                <Box sx={{ mb: 3 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 1 }}>
                        <Box>
                            <Typography level="h2" sx={{ fontSize: { xs: '1.5rem', sm: '1.875rem', md: '2.25rem' } }}>
                                Posts Management
                            </Typography>
                            <Typography level="body-sm" sx={{ color: 'neutral.500' }}>
                                View and manage all posts in the platform
                            </Typography>
                        </Box>
                        <Button
                            variant="outlined"
                            color="neutral"
                            loading={loading}
                            onClick={fetchPosts}
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
                    searchPlaceholder="Search posts..."
                />
            </Box>
        </motion.div>
    )
}

export default PostsManagement