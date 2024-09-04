 namespace DragonReborn
 {
     public class LinkedList
     {
         public class Node
         {
             public Node Prev;
             public Node Next;
         }

         private readonly Node _null = new Node();

         public LinkedList()
         {
             _null.Next = _null;
             _null.Prev = _null;
         }

         public Node GetFirst()
         {
             return _null.Next;
         }

         public Node GetLast()
         {
             return _null.Prev;
         }

         public Node GetEnd()
         {
             return _null;
         }

         public void PushBack(Node node)
         {
             var prev = _null.Prev;
		
             prev.Next = node;
             node.Prev = prev;
		
             node.Next = _null;
             _null.Prev = node;
         }

         public Node PopBack()
         {
             if (IsEmpty())
             {
                 return null;
             }
             
             var node = _null.Prev;
             var prev = node.Prev;

             prev.Next = _null;
             _null.Prev = prev;

             node.Prev = null;
             node.Next = null;

             return node;
         }
	
         public void PushFront(Node node)
         {
             var next = _null.Next;
		
             next.Prev = node;
             node.Next = next;
		
             node.Prev = _null;
             _null.Next = node;
         }

         public Node PopFront()
         {
             if (IsEmpty())
             {
                 return null;
             }
             
             var node = _null.Next;
             var next = node.Next;

             next.Prev = _null;
             _null.Next = next;

             node.Prev = null;
             node.Next = null;

             return node;
         }
	
         public void Remove(Node node)
         {
             var prev = node.Prev;
             var next = node.Next;
		
             prev.Next = next;
             next.Prev = prev;
		
             node.Prev = null;
             node.Next = null;
         }

         public bool IsEmpty()
         {
             return _null.Prev == _null && _null.Next == _null;
         }
     }
 }