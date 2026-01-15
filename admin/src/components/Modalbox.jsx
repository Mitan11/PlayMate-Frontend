import Modal from '@mui/joy/Modal';
import ModalClose from '@mui/joy/ModalClose';
import Typography from '@mui/joy/Typography';
import Sheet from '@mui/joy/Sheet';
import Button from '@mui/joy/Button';
import Box from '@mui/joy/Box';

export default function Modalbox({ 
    open, 
    setOpen, 
    title, 
    children, 
    onConfirm, 
    onCancel, 
    confirmText = "Confirm", 
    cancelText = "Cancel", 
    showActions = true,
    width = 500,
    minWidth = 300
}) {
    const handleConfirm = () => {
        if (onConfirm) onConfirm();
        setOpen(false);
    };

    const handleCancel = () => {
        if (onCancel) onCancel();
        setOpen(false);
    };

    return (
        <Modal
            aria-labelledby="modal-title"
            aria-describedby="modal-desc"
            open={open}
            onClose={() => setOpen(false)}
            sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}
        >
            <Sheet
                variant="outlined"
                sx={{ 
                    maxWidth: width, 
                    minWidth: minWidth,
                    width: '90vw',
                    borderRadius: 'md', 
                    p: 3, 
                    boxShadow: 'lg' 
                }}
            >
                <ModalClose variant="plain" sx={{ m: 1 }} />
                <Typography
                    component="h2"
                    id="modal-title"
                    level="h4"
                    textColor="inherit"
                    sx={{ fontWeight: 'lg', mb: 1 }}
                >
                    {title}
                </Typography>
                {children}
                {showActions && (
                    <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
                        <Button variant="plain" color="neutral" onClick={handleCancel}>
                            {cancelText}
                        </Button>
                        <Button variant="solid" color="danger" onClick={handleConfirm}>
                            {confirmText}
                        </Button>
                    </Box>
                )}
            </Sheet>
        </Modal>
    )
}
