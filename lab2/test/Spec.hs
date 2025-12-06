{-# OPTIONS_GHC -Wno-orphans #-}
import Test.Hspec
import Test.QuickCheck
import Test.QuickCheck.Function
import Data.AVLSet

newtype IntSet = IntSet (AVLSet Int) deriving Show

instance Arbitrary IntSet where
  arbitrary = do
    xs <- listOf (arbitrary :: Gen Int)
    pure (IntSet (fromList xs))

prop_monoid_left_id :: IntSet -> Bool
prop_monoid_left_id (IntSet s) = (mempty <> s) == s

prop_monoid_right_id :: IntSet -> Bool
prop_monoid_right_id (IntSet s) = (s <> mempty) == s

prop_monoid_assoc :: IntSet -> IntSet -> IntSet -> Bool
prop_monoid_assoc (IntSet a) (IntSet b) (IntSet c) = ((a <> b) <> c) == (a <> (b <> c))

prop_valid_avl :: IntSet -> Bool
prop_valid_avl (IntSet s) = validAVL s

prop_map_comp :: IntSet -> Bool
prop_map_comp (IntSet s) = mapSet ((+1) . (*2)) s == mapSet (+1) (mapSet (*2) s)

prop_union_member :: Int -> IntSet -> IntSet -> Bool
prop_union_member x (IntSet a) (IntSet b) = member x (a <> b) == (member x a || member x b)

prop_insert_member :: Int -> IntSet -> Bool
prop_insert_member x (IntSet s) = member x (insert x s)

prop_delete_member :: Int -> IntSet -> Bool
prop_delete_member x (IntSet s) = not (member x (delete x (insert x s)))

prop_filter_preserve :: Fun Int Bool -> IntSet -> Bool
prop_filter_preserve (Fun _ p) (IntSet s) = all p (toList (filterSet p s))

main :: IO ()
main = hspec $ do
  describe "AVLSet basic unit tests" $ do
    it "insert then member" $ member 5 (insert 5 empty :: AVLSet Int) `shouldBe` True
    it "delete removes element" $ let s = delete 3 (insert 3 empty :: AVLSet Int) in member 3 s `shouldBe` False
  describe "AVLSet properties" $ do
    it "Monoid left identity" $ property prop_monoid_left_id
    it "Monoid right identity" $ property prop_monoid_right_id
    it "Monoid associativity" $ property prop_monoid_assoc
    it "AVL invariant holds" $ property prop_valid_avl
    it "Map composition" $ property prop_map_comp
    it "Union membership" $ property prop_union_member
    it "Insert membership" $ property prop_insert_member
    it "Delete membership after insert" $ property prop_delete_member
    it "Filter preserves predicate" $ property prop_filter_preserve
