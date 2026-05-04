import React, { useRef, useEffect } from 'react';
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, LineElement, PointElement, Title, Tooltip, Legend, Filler } from 'chart.js';
import { Bar } from 'react-chartjs-2';

ChartJS.register(CategoryScale, LinearScale, BarElement, LineElement, PointElement, Title, Tooltip, Legend, Filler);

export default function WeeklyChart({ data }) {
  const chartRef = useRef(null);

  const chartData = {
    labels: data.map(d => d.day),
    datasets: [
      {
        label: 'Fitness',
        data: data.map(d => d.fitness),
        backgroundColor: 'rgba(108, 92, 231, 0.6)',
        borderColor: 'rgba(108, 92, 231, 1)',
        borderWidth: 1,
        borderRadius: 6,
        borderSkipped: false,
      },
      {
        label: 'Running',
        data: data.map(d => d.running),
        backgroundColor: 'rgba(0, 210, 211, 0.5)',
        borderColor: 'rgba(0, 210, 211, 1)',
        borderWidth: 1,
        borderRadius: 6,
        borderSkipped: false,
      },
      {
        label: 'Study',
        data: data.map(d => d.study),
        backgroundColor: 'rgba(240, 147, 251, 0.4)',
        borderColor: 'rgba(240, 147, 251, 1)',
        borderWidth: 1,
        borderRadius: 6,
        borderSkipped: false,
      },
    ],
  };

  const options = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'bottom',
        labels: {
          color: 'rgba(200, 196, 215, 0.8)',
          font: { family: 'Inter', size: 11, weight: '500' },
          usePointStyle: true,
          pointStyle: 'circle',
          padding: 20,
        },
      },
      tooltip: {
        backgroundColor: 'rgba(23, 31, 51, 0.95)',
        borderColor: 'rgba(255, 255, 255, 0.1)',
        borderWidth: 1,
        titleFont: { family: 'Inter', weight: '600' },
        bodyFont: { family: 'Inter' },
        cornerRadius: 12,
        padding: 12,
      },
    },
    scales: {
      x: {
        grid: { color: 'rgba(255, 255, 255, 0.03)', drawBorder: false },
        ticks: {
          color: 'rgba(200, 196, 215, 0.6)',
          font: { family: 'Inter', size: 11, weight: '500' },
        },
        border: { display: false },
      },
      y: {
        grid: { color: 'rgba(255, 255, 255, 0.03)', drawBorder: false },
        ticks: {
          color: 'rgba(200, 196, 215, 0.6)',
          font: { family: 'Inter', size: 11 },
        },
        border: { display: false },
        beginAtZero: true,
      },
    },
    animation: {
      duration: 1000,
      easing: 'easeOutQuart',
    },
  };

  return (
    <div style={{ height: 280 }}>
      <Bar ref={chartRef} data={chartData} options={options} />
    </div>
  );
}
