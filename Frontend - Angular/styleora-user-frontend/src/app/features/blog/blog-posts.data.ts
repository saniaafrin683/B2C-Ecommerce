export interface BlogPost {
  id: string;
  title: string;
  category: string;
  date: string;
  excerpt: string;
  image: string;
  content: string[];
}

export const BLOG_POSTS: BlogPost[] = [
  {
    id: 'summer-capsule-wardrobe',
    title: 'Build a Summer Capsule Wardrobe That Works Every Day',
    category: 'Style Guide',
    date: '2026-05-01',
    excerpt: 'Start with breathable basics, repeatable layers, and a few polished accents that make getting dressed faster.',
    image: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=1200&q=80',
    content: [
      'A strong summer wardrobe does not need to be large. It needs to be easy to mix, comfortable in warm weather, and polished enough for work, errands, and casual plans.',
      'Start with neutral tops, relaxed trousers, clean denim, and lightweight outer layers. Then add one or two statement pieces that give the lineup personality without making styling difficult.',
      'At Styleora, we recommend building around pieces you can wear three different ways. That keeps your wardrobe practical while still feeling styled and current.'
    ]
  },
  {
    id: 'denim-fit-guide',
    title: 'The Denim Fit Guide: Finding the Pair You Will Actually Rewear',
    category: 'Buying Tips',
    date: '2026-04-26',
    excerpt: 'From straight-leg classics to relaxed silhouettes, this guide helps you choose denim that fits both your routine and shape.',
    image: 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?auto=format&fit=crop&w=1200&q=80',
    content: [
      'Denim works best when the fit matches how you move through the day. A pair that looks good standing still but feels restrictive after an hour will not stay in rotation.',
      'Straight and relaxed fits remain the easiest starting point because they work with sneakers, loafers, and sandals while staying comfortable for long wear.',
      'When you shop denim, focus on rise, fabric weight, and stretch before trend details. Those factors determine whether the pair becomes a staple or stays in the closet.'
    ]
  },
  {
    id: 'accessories-for-minimal-looks',
    title: 'Accessories That Make Minimal Outfits Feel Finished',
    category: 'Accessories',
    date: '2026-04-18',
    excerpt: 'A structured bag, clean jewelry, and one intentional texture can turn a simple outfit into a complete look.',
    image: 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=1200&q=80',
    content: [
      'Minimal dressing does not mean empty styling. The difference usually comes from one or two accessories that add shape, shine, or contrast.',
      'Choose pieces that are easy to repeat: a refined shoulder bag, slim gold or silver jewelry, and sunglasses with a clean frame shape are reliable starting points.',
      'The goal is consistency. Small accessories that work across multiple outfits give your wardrobe a stronger identity without adding clutter.'
    ]
  },
  {
    id: 'weekend-travel-packing',
    title: 'Weekend Packing for Fashion Without Overpacking',
    category: 'Lifestyle',
    date: '2026-04-10',
    excerpt: 'Pack lighter by choosing coordinated outfits, multipurpose shoes, and one elevated layer for dinners or photos.',
    image: 'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?auto=format&fit=crop&w=1200&q=80',
    content: [
      'Weekend trips are the easiest place to overpack. The fix is to build around one color story and choose items that can shift from day to evening with only minor changes.',
      'Instead of packing separate outfits for every plan, take interchangeable tops and bottoms, a lightweight jacket, and shoes you know you can walk in comfortably.',
      'A tighter packing edit usually creates better outfits because every piece has a clear role. That makes travel styling simpler and faster.'
    ]
  }
];
