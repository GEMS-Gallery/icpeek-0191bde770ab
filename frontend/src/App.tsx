import React, { useState, useEffect, useCallback } from 'react';
import { backend } from 'declarations/backend';
import { Container, Typography, Box, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, CircularProgress, Button, Snackbar } from '@mui/material';
import RefreshIcon from '@mui/icons-material/Refresh';
import Alert from '@mui/material/Alert';

type OrderbookEntry = {
  price: number;
  quantity: number;
};

type Orderbook = {
  bids: OrderbookEntry[];
  asks: OrderbookEntry[];
};

const BINANCE_API_URL = 'https://api.binance.com/api/v3';
const SYMBOL = 'ICPUSDT';

const App: React.FC = () => {
  const [orderbook, setOrderbook] = useState<Orderbook | null>(null);
  const [lastUpdateTime, setLastUpdateTime] = useState<number | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [spread, setSpread] = useState<number | null>(null);
  const [totalVolume, setTotalVolume] = useState<number | null>(null);
  const [snackbarOpen, setSnackbarOpen] = useState<boolean>(false);

  const fetchOrderbookFromBinance = async (limit = 10) => {
    const url = `${BINANCE_API_URL}/depth?symbol=${SYMBOL}&limit=${limit}`;
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const data = await response.json();
    return {
      bids: data.bids.map(([price, quantity]: [string, string]) => [price, quantity]),
      asks: data.asks.map(([price, quantity]: [string, string]) => [price, quantity])
    };
  };

  const fetchOrderbook = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const isHealthy = await backend.healthCheck();
      if (!isHealthy) {
        throw new Error("Backend is not healthy");
      }

      const binanceData = await fetchOrderbookFromBinance();
      await backend.updateOrderbook(binanceData.bids, binanceData.asks);
      const result = await backend.getOrderbook();
      if ('ok' in result) {
        setOrderbook(result.ok);
      } else {
        throw new Error(result.err);
      }

      const updateTime = await backend.getLastUpdateTime();
      setLastUpdateTime(Number(updateTime));

      const spreadResult = await backend.getSpread();
      if ('ok' in spreadResult) {
        setSpread(spreadResult.ok);
      }

      const volumeResult = await backend.getTotalVolume();
      if ('ok' in volumeResult) {
        setTotalVolume(volumeResult.ok);
      }
    } catch (err) {
      setError('Failed to fetch orderbook: ' + (err instanceof Error ? err.message : String(err)));
      setSnackbarOpen(true);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchOrderbook();
    const interval = setInterval(fetchOrderbook, 10000); // Refresh every 10 seconds
    return () => clearInterval(interval);
  }, [fetchOrderbook]);

  const handleSnackbarClose = (event?: React.SyntheticEvent | Event, reason?: string) => {
    if (reason === 'clickaway') {
      return;
    }
    setSnackbarOpen(false);
  };

  const renderOrderbookTable = (entries: OrderbookEntry[], type: 'bids' | 'asks') => (
    <TableContainer component={Paper}>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Price</TableCell>
            <TableCell align="right">Quantity</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {entries.map((entry, index) => (
            <TableRow key={index} sx={{ backgroundColor: type === 'bids' ? 'rgba(46, 204, 113, 0.1)' : 'rgba(231, 76, 60, 0.1)' }}>
              <TableCell component="th" scope="row">
                {entry.price.toFixed(4)}
              </TableCell>
              <TableCell align="right">{entry.quantity.toFixed(4)}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );

  return (
    <Container maxWidth="lg">
      <Box sx={{ my: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          ICP/USDT Orderbook
        </Typography>
        {loading && <CircularProgress />}
        {error && (
          <Box sx={{ mb: 2 }}>
            <Typography color="error">{error}</Typography>
            <Button variant="contained" onClick={fetchOrderbook} startIcon={<RefreshIcon />}>
              Retry
            </Button>
          </Box>
        )}
        {orderbook && (
          <>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
              <Typography variant="subtitle1">
                Last updated: {new Date(lastUpdateTime || 0).toLocaleString()}
              </Typography>
              <Button variant="outlined" onClick={fetchOrderbook} startIcon={<RefreshIcon />}>
                Refresh
              </Button>
            </Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
              <Box sx={{ width: '48%' }}>
                <Typography variant="h6">Bids</Typography>
                {renderOrderbookTable(orderbook.bids, 'bids')}
              </Box>
              <Box sx={{ width: '48%' }}>
                <Typography variant="h6">Asks</Typography>
                {renderOrderbookTable(orderbook.asks, 'asks')}
              </Box>
            </Box>
            <Box sx={{ mt: 2 }}>
              <Typography variant="subtitle1">
                Spread: {spread !== null ? spread.toFixed(4) : 'N/A'}
              </Typography>
              <Typography variant="subtitle1">
                Total Volume: {totalVolume !== null ? totalVolume.toFixed(4) : 'N/A'}
              </Typography>
            </Box>
          </>
        )}
      </Box>
      <Snackbar open={snackbarOpen} autoHideDuration={6000} onClose={handleSnackbarClose}>
        <Alert onClose={handleSnackbarClose} severity="error" sx={{ width: '100%' }}>
          {error}
        </Alert>
      </Snackbar>
    </Container>
  );
};

export default App;
