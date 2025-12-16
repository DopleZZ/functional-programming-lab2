{-# LANGUAGE DeriveFoldable #-}
module Data.AVLSet
  ( AVLSet
  , empty
  , singleton
  , insert
  , delete
  , member
  , fromList
  , toList
  , mapSet
  , filterSet
  , foldrSet
  , foldlSet
  , union
  , validAVL
  ) where



data Tree a = Empty | Node !(Tree a) !a !(Tree a) !Int

newtype AVLSet a = AVLSet { unSet :: Tree a }

empty :: AVLSet a
empty = AVLSet Empty

singleton :: a -> AVLSet a
singleton x = AVLSet (Node Empty x Empty 1)

height :: Tree a -> Int
height Empty = 0
height (Node _ _ _ h) = h

mkNode :: Tree a -> a -> Tree a -> Tree a
mkNode l x r = Node l x r (1 + max (height l) (height r))

balanceFactor :: Tree a -> Int
balanceFactor Empty = 0
balanceFactor (Node l _ r _) = height l - height r

rotateLeft :: Tree a -> Tree a
rotateLeft (Node a x (Node b y c hR) _ ) = mkNode (mkNode a x b) y c
rotateLeft t = t

rotateRight :: Tree a -> Tree a
rotateRight (Node (Node a x b hL) y c _ ) = mkNode a x (mkNode b y c)
rotateRight t = t

rebalance :: Tree a -> Tree a
rebalance t@(Node l x r _) =
  case balanceFactor t of
    bf | bf > 1 -> 
          let l' = case l of
                     Node ll lx lr _ | balanceFactor l < 0 -> rotateLeft l
                     _ -> l
          in mkNode (case l' of Node ll lx lr _ -> ll; _ -> Empty)
                               (case l' of Node _ lx _ _ -> lx; _ -> x)
                               (mkNode (case l' of Node _ _ lr _ -> lr; _ -> Empty) x r)
       | bf < -1 -> 
          let r' = case r of
                     Node rl rx rr _ | balanceFactor r > 0 -> rotateRight r
                     _ -> r
          in mkNode (mkNode l x (case r' of Node rl _ _ _ -> rl; _ -> Empty))
                               (case r' of Node _ rx _ _ -> rx; _ -> x)
                               (case r' of Node _ _ rr _ -> rr; _ -> Empty)
       | otherwise -> mkNode l x r
rebalance t = t

insertTree :: Ord a => a -> Tree a -> Tree a
insertTree x Empty = Node Empty x Empty 1
insertTree x (Node l y r _) =
  case compare x y of
    LT -> rebalance (mkNode (insertTree x l) y r)
    GT -> rebalance (mkNode l y (insertTree x r))
    EQ -> mkNode l y r 

deleteTree :: Ord a => a -> Tree a -> Tree a
deleteTree _ Empty = Empty
deleteTree x (Node l y r _) =
  case compare x y of
    LT -> rebalance (mkNode (deleteTree x l) y r)
    GT -> rebalance (mkNode l y (deleteTree x r))
    EQ -> deleteRoot l r

deleteRoot :: Tree a -> Tree a -> Tree a
deleteRoot Empty r = r
deleteRoot l Empty = l
deleteRoot l r = let (m, r') = extractMin r in rebalance (mkNode l m r')

extractMin :: Tree a -> (a, Tree a)
extractMin (Node Empty x r _) = (x, r)
extractMin (Node l x r _) = let (m, l') = extractMin l in (m, rebalance (mkNode l' x r))
extractMin Empty = error "extractMin on empty"

memberTree :: Ord a => a -> Tree a -> Bool
memberTree _ Empty = False
memberTree x (Node l y r _) =
  case compare x y of
    LT -> memberTree x l
    GT -> memberTree x r
    EQ -> True

toListTree :: Tree a -> [a]
toListTree Empty = []
toListTree (Node l x r _) = toListTree l ++ (x : toListTree r)

insert :: Ord a => a -> AVLSet a -> AVLSet a
insert x (AVLSet t) = AVLSet (insertTree x t)

delete :: Ord a => a -> AVLSet a -> AVLSet a
delete x (AVLSet t) = AVLSet (deleteTree x t)

member :: Ord a => a -> AVLSet a -> Bool
member x (AVLSet t) = memberTree x t

fromList :: Ord a => [a] -> AVLSet a
fromList = foldr insert empty

toList :: AVLSet a -> [a]
toList (AVLSet t) = toListTree t

mapSet :: Ord b => (a -> b) -> AVLSet a -> AVLSet b
mapSet f = foldrSet (insert . f) empty

filterSet :: Ord a => (a -> Bool) -> AVLSet a -> AVLSet a
filterSet p = foldrSet (\x acc -> if p x then insert x acc else acc) empty

foldrSet :: (a -> b -> b) -> b -> AVLSet a -> b
foldrSet f z (AVLSet t) = go t z
  where
    go Empty acc = acc
    go (Node l x r _) acc = go l (f x (go r acc))

foldlSet :: (b -> a -> b) -> b -> AVLSet a -> b
foldlSet f z (AVLSet t) = go t z
  where
    go Empty acc = acc
    go (Node l x r _) acc = let acc' = go l acc in go r (f acc' x)

union :: Ord a => AVLSet a -> AVLSet a -> AVLSet a
union a b = foldrSet insert b a

instance Eq a => Eq (AVLSet a) where
  (AVLSet t1) == (AVLSet t2) = toListTree t1 == toListTree t2

instance (Ord a) => Semigroup (AVLSet a) where
  (<>) = union

instance (Ord a) => Monoid (AVLSet a) where
  mempty = empty
  mappend = (<> )

validAVL :: AVLSet a -> Bool
validAVL (AVLSet t) = valid t /= Nothing
  where
    valid Empty = Just 0
    valid (Node l _ r h) = do
      hl <- valid l
      hr <- valid r
      let hCalc = 1 + max hl hr
      if h == hCalc && abs (hl - hr) <= 1 then Just hCalc else Nothing

instance Foldable AVLSet where
  foldr f z (AVLSet t) = foldr f z (toListTree t)

instance Show a => Show (AVLSet a) where
  show s = "AVLSet " ++ show (toList s)
