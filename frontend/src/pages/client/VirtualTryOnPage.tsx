import { useEffect, useRef, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Camera, CameraOff, ArrowLeft, Download } from 'lucide-react';
import api, { mediaUrl, formatCFA } from '@/lib/api';
import { Monture } from '@/types';
import toast from 'react-hot-toast';

export default function VirtualTryOnPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const [cameraActive, setCameraActive] = useState(false);
  const [faceDetected, setFaceDetected] = useState(false);
  const [saving, setSaving] = useState(false);

  const { data: monture } = useQuery<Monture>({
    queryKey: ['monture', id],
    queryFn: () => api.get(`/montures/${id}/`).then(r => r.data),
  });

  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user', width: 640, height: 480 } });
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        videoRef.current.play();
      }
      setCameraActive(true);
      startFaceDetection();
    } catch {
      toast.error("Impossible d'accéder à la caméra");
    }
  };

  const stopCamera = () => {
    streamRef.current?.getTracks().forEach(t => t.stop());
    streamRef.current = null;
    setCameraActive(false);
    setFaceDetected(false);
  };

  const startFaceDetection = () => {
    const couleurMap: Record<string, string> = {
      'noir': '#111111', 'noire': '#111111',
      'marron': '#6B3A2A', 'brun': '#6B3A2A', 'brune': '#6B3A2A',
      'or': '#C8A951', 'doré': '#C8A951', 'dorée': '#C8A951',
      'argent': '#A8A8A8', 'argenté': '#A8A8A8', 'argentée': '#A8A8A8',
      'rouge': '#CC2200',
      'bleu': '#1a3a8b', 'bleue': '#1a3a8b',
      'vert': '#1a6b3a', 'verte': '#1a6b3a',
      'rose': '#CC6688',
      'transparent': 'rgba(150,200,255,0.25)', 'transparente': 'rgba(150,200,255,0.25)',
      'blanc': '#D8D8D8', 'blanche': '#D8D8D8',
      'violet': '#6B1a8b', 'violette': '#6B1a8b',
    };

    const drawGlasses = (
      ctx: CanvasRenderingContext2D,
      fx: number, fy: number, fw: number, fh: number,
      frameColor: string, forme: string
    ) => {
      const eyeY = fy + fh * 0.40;
      const lensW = fw * 0.37;
      const lensH = fh * 0.22;
      const leftCX = fx + fw * 0.27;
      const rightCX = fx + fw * 0.73;
      const frameStroke = Math.max(3, fw * 0.012);

      ctx.save();
      ctx.shadowColor = 'rgba(0,0,0,0.45)';
      ctx.shadowBlur = 8;
      ctx.shadowOffsetY = 3;
      ctx.strokeStyle = frameColor;
      ctx.lineWidth = frameStroke;
      ctx.fillStyle = 'rgba(200,230,255,0.06)';

      const drawLens = (cx: number) => {
        const f = forme.toLowerCase();
        if (f === 'rectangulaire' || f === 'rectangle') {
          const r = lensH * 0.25;
          ctx.beginPath();
          if (ctx.roundRect) ctx.roundRect(cx - lensW / 2, eyeY - lensH / 2, lensW, lensH, r);
          else ctx.rect(cx - lensW / 2, eyeY - lensH / 2, lensW, lensH);
          ctx.fill(); ctx.stroke();
        } else if (f === 'carree' || f === 'carré') {
          const size = Math.min(lensW * 0.9, lensH * 1.3);
          const r = size * 0.1;
          ctx.beginPath();
          if (ctx.roundRect) ctx.roundRect(cx - size / 2, eyeY - size / 2, size, size, r);
          else ctx.rect(cx - size / 2, eyeY - size / 2, size, size);
          ctx.fill(); ctx.stroke();
        } else if (f === 'ronde' || f === 'rond') {
          const r = Math.min(lensW, lensH) / 2;
          ctx.beginPath();
          ctx.arc(cx, eyeY, r, 0, 2 * Math.PI);
          ctx.fill(); ctx.stroke();
        } else {
          ctx.beginPath();
          ctx.ellipse(cx, eyeY, lensW / 2, lensH / 2, 0, 0, 2 * Math.PI);
          ctx.fill(); ctx.stroke();
        }
      };

      drawLens(leftCX);
      drawLens(rightCX);

      ctx.shadowColor = 'transparent';
      ctx.shadowBlur = 0;
      ctx.shadowOffsetY = 0;
      ctx.lineWidth = frameStroke - 1;

      // Pont nasal
      ctx.beginPath();
      ctx.moveTo(leftCX + lensW / 2, eyeY);
      ctx.lineTo(rightCX - lensW / 2, eyeY);
      ctx.stroke();

      // Branche gauche
      ctx.beginPath();
      ctx.moveTo(leftCX - lensW / 2, eyeY);
      ctx.lineTo(fx - fw * 0.05, eyeY);
      ctx.stroke();

      // Branche droite
      ctx.beginPath();
      ctx.moveTo(rightCX + lensW / 2, eyeY);
      ctx.lineTo(fx + fw + fw * 0.05, eyeY);
      ctx.stroke();

      ctx.restore();
    };

    const detect = () => {
      if (!videoRef.current || !canvasRef.current) return;
      const ctx = canvasRef.current.getContext('2d');
      if (!ctx) return;
      const { videoWidth: w, videoHeight: h } = videoRef.current;
      if (w === 0 || h === 0) { if (streamRef.current) requestAnimationFrame(detect); return; }
      canvasRef.current.width = w;
      canvasRef.current.height = h;
      ctx.drawImage(videoRef.current, 0, 0);

      const fx = w * 0.25, fy = h * 0.1, fw = w * 0.5, fh = h * 0.5;

      // Coins de guidage discrets
      const cornerSize = 18;
      ctx.strokeStyle = 'rgba(255,255,255,0.55)';
      ctx.lineWidth = 2;
      const corners = [
        [fx, fy, cornerSize, 0, 0, cornerSize],
        [fx + fw, fy, -cornerSize, 0, 0, cornerSize],
        [fx, fy + fh, cornerSize, 0, 0, -cornerSize],
        [fx + fw, fy + fh, -cornerSize, 0, 0, -cornerSize],
      ] as const;
      for (const [ox, oy, dx1, dy1, dx2, dy2] of corners) {
        ctx.beginPath();
        ctx.moveTo(ox + dx1, oy + dy1);
        ctx.lineTo(ox, oy);
        ctx.lineTo(ox + dx2, oy + dy2);
        ctx.stroke();
      }

      if (monture) {
        const key = monture.couleur?.toLowerCase().trim() || 'noir';
        const frameColor = couleurMap[key] ?? '#222222';
        const forme = monture.forme ?? 'ovale';
        drawGlasses(ctx, fx, fy, fw, fh, frameColor, forme);
      }

      setFaceDetected(true);
      if (streamRef.current) requestAnimationFrame(detect);
    };
    videoRef.current?.addEventListener('play', () => requestAnimationFrame(detect), { once: true });
  };

  const takeScreenshot = async () => {
    if (!canvasRef.current) return;
    setSaving(true);
    try {
      canvasRef.current.toBlob(async (blob) => {
        if (!blob) return;
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `essai-${monture?.nom || 'monture'}.png`;
        a.click();
        URL.revokeObjectURL(url);
        try {
          const formData = new FormData();
          formData.append('image', blob, 'essai.png');
          formData.append('monture_id', id!);
          await api.post('/essai/essayer/', formData, { headers: { 'Content-Type': 'multipart/form-data' } });
        } catch { /* non-blocking */ }
        toast.success('Essai sauvegardé !');
        setSaving(false);
      });
    } catch {
      toast.error('Erreur lors de la sauvegarde');
      setSaving(false);
    }
  };

  useEffect(() => () => stopCamera(), []);

  const imgSrc = monture?.image_principale ? mediaUrl(monture.image_principale) : monture?.images?.[0] ? mediaUrl(monture.images[0]) : null;

  return (
    <div>
      <button onClick={() => { stopCamera(); navigate(-1); }} className="flex items-center gap-2 text-gray-500 hover:text-gray-700 mb-6 text-sm">
        <ArrowLeft className="w-4 h-4" /> Retour
      </button>

      <div className="flex flex-col lg:flex-row gap-8">
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-gray-900 mb-2">Essai virtuel</h1>
          {monture && <p className="text-gray-500 text-sm mb-4">Vous essayez : <strong>{monture.nom}</strong> — {monture.marque}</p>}

          <div className="relative bg-gray-900 rounded-2xl overflow-hidden aspect-video">
            <video ref={videoRef} className={`absolute inset-0 w-full h-full object-cover ${cameraActive ? '' : 'hidden'}`} muted playsInline />
            <canvas ref={canvasRef} className={`absolute inset-0 w-full h-full ${cameraActive ? '' : 'hidden'}`} />
            {!cameraActive && (
              <div className="flex flex-col items-center justify-center h-full text-white gap-4 py-16">
                <CameraOff className="w-16 h-16 opacity-40" />
                <p className="text-gray-400">Activez la caméra pour l'essai virtuel</p>
              </div>
            )}
            {cameraActive && faceDetected && (
              <div className="absolute top-3 left-3 bg-green-500 text-white text-xs font-medium px-2 py-1 rounded-full">Centrez votre visage</div>
            )}
          </div>

          <div className="flex gap-3 mt-4">
            {!cameraActive ? (
              <button onClick={startCamera} className="btn-primary flex items-center gap-2 flex-1">
                <Camera className="w-4 h-4" /> Activer la caméra
              </button>
            ) : (
              <>
                <button onClick={stopCamera} className="btn-secondary flex items-center gap-2 flex-1">
                  <CameraOff className="w-4 h-4" /> Arrêter
                </button>
                <button onClick={takeScreenshot} disabled={saving} className="btn-primary flex items-center gap-2 flex-1">
                  <Download className="w-4 h-4" /> {saving ? 'Sauvegarde...' : 'Capturer'}
                </button>
              </>
            )}
          </div>
        </div>

        {monture && (
          <div className="lg:w-72">
            <div className="card">
              <h3 className="font-semibold text-gray-900 mb-3">Détails de la monture</h3>
              {imgSrc && <img src={imgSrc} alt={monture.nom} className="w-full h-32 object-cover rounded-xl mb-3" />}
              <div className="space-y-2 text-sm">
                <div className="flex justify-between"><span className="text-gray-500">Marque</span><span className="font-medium">{monture.marque}</span></div>
                <div className="flex justify-between"><span className="text-gray-500">Forme</span><span className="font-medium">{monture.forme}</span></div>
                <div className="flex justify-between"><span className="text-gray-500">Couleur</span><span className="font-medium">{monture.couleur}</span></div>
                <div className="flex justify-between"><span className="text-gray-500">Prix</span><span className="font-bold text-primary-600">{formatCFA(monture.prix)}</span></div>
              </div>
              <button onClick={() => navigate(`/montures/${monture.id}`)} className="btn-primary w-full mt-4 text-sm">
                Commander cette monture
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
